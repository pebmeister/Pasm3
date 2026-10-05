#pragma once
#include <sstream>
#include <format>
#include <string>
#include <vector>
#include <queue>
#include <mutex>
#include <condition_variable>
#include <thread>
#include <atomic>
#include <functional>
#include <iostream>

#include "ruletype.h"
#include "tokenkind.h"
#include "AssemblerParser.h"
#include "PasmTokenizer.hpp"
#include "multipassassembler.h"
#include "options.h"
#include "sourceManager.h"
#include "utilities.h"
#include "autoloader.h"
#include "ANSI_esc.h"

/**
 * @brief Concurrent test runner engine using streaming test generation and multi-threaded execution.
 */
class TestRunner
{
public:
    struct Test {
        SourceManager src_mgr;
        std::string source_code;
        std::vector<uint8_t> expected;
        bool negative_test;

        Test(
            SourceManager src_mgr,
            std::string_view source_code,
            std::vector<uint8_t> expected,
            bool negative_test = false) 
            : src_mgr(std::move(src_mgr)),
              source_code(std::move(source_code)),
              expected(std::move(expected)),
              negative_test(negative_test) {}
    };

    std::string error;
    std::string source_code;

    /**
     * @brief Streams generated tests one by one via the emit callback.
     * @param max_iterations Maximum number of test cases to generate per mode/opcode.
     * @param emit Callback function invoked to stream each constructed test case into the queue.
     */
    virtual void generate_tests(int max_iterations, const std::function<void(Test)>& emit) = 0;

    /**
     * @brief Runs the streamed unit tests concurrently across all system threads.
     * @param col Terminal output column offset for progress reporting.
     * @param exit_on_fail If true, halts execution immediately upon encountering a test failure.
     * @param max_iterations Iteration cap passed down to generate_tests.
     * @return int Returns 0 on success (all passed), or 1 if any tests failed.
     */
    int test(int col, bool exit_on_fail, int max_iterations)
    {         
        constexpr int fileid = 0;
        std::stringstream error_ss;

        std::atomic<bool> overall_passed{true};
        std::atomic<int> passed_count{0};
        std::atomic<int> failed_count{0};
        std::atomic<int> total_processed{0};
        std::atomic<bool> stop_requested{false};

        // Bounded thread-safe queue to keep memory lightweight
        std::queue<Test> test_queue;
        std::mutex queue_mutex;
        std::condition_variable cv_producer;
        std::condition_variable cv_workers;
        bool generation_complete = false;
        constexpr size_t MAX_QUEUE_CAPACITY = 1000;

        std::mutex console_mutex;

		std::exception_ptr producer_exception = nullptr;

		// 1. Producer Thread
		std::thread producer([&]() {
    		try {
        		generate_tests(max_iterations, [&](Test test_item) {
            		if (stop_requested.load(std::memory_order_relaxed)) return;

            		std::unique_lock<std::mutex> lock(queue_mutex);
            		cv_producer.wait(lock, [&]() {
                		return test_queue.size() < MAX_QUEUE_CAPACITY || stop_requested.load(std::memory_order_relaxed);
            		});

            		if (stop_requested.load(std::memory_order_relaxed)) return;

            		test_queue.push(std::move(test_item));
            		lock.unlock();
            		cv_workers.notify_one();
        		});
    		}
    		catch (...) {
        		// Capture the exception thrown during test generation
        		producer_exception = std::current_exception();

        		// Signal worker threads to halt immediately
        		stop_requested.store(true, std::memory_order_relaxed);
        		cv_workers.notify_all();
    		}

    		{
        		std::lock_guard<std::mutex> lock(queue_mutex);
        		generation_complete = true;
    		}
    		cv_workers.notify_all();
		});

        // 2. Worker Threads: Process tests in parallel
        unsigned int num_workers = std::thread::hardware_concurrency();
        if (num_workers == 0) num_workers = 4;

        std::vector<std::thread> workers;
        workers.reserve(num_workers);

        for (unsigned int i = 0; i < num_workers; ++i) {
            workers.emplace_back([&]() {
                PasmTokenizer tokenizer;
                Options options;
                options.verbose = false;

                while (true) {
                    Test current_test(SourceManager{}, "", {});

                    {
                        std::unique_lock<std::mutex> lock(queue_mutex);
                        cv_workers.wait(lock, [&]() {
                            return !test_queue.empty() || generation_complete || stop_requested.load(std::memory_order_relaxed);
                        });

                        if (stop_requested.load(std::memory_order_relaxed)) return;
                        if (test_queue.empty() && generation_complete) return;

                        current_test = std::move(test_queue.front());
                        test_queue.pop();
                        cv_producer.notify_one();
                    }

                    // Run assembly test instance
                    bool test_passed = false;
                    std::string fail_msg;

                    try {
                        auto tokens = tokenizer.tokenize(current_test.source_code, fileid);
                        AssemblerParser parser(tokens, options, current_test.src_mgr);
                        auto statements = parser.ParseProgram(tokenizer);
                        MultiPassAssembler assembler(options);
                        assembler.Assemble(statements, current_test.src_mgr);

                        if (current_test.negative_test) {
                            test_passed = (current_test.expected != assembler.binary_output);
                            if (!test_passed) {
                                fail_msg = "FAILED (Negative Test): Assembly succeeded on invalid input.\n";
                            }
                        } else {
                            test_passed = (current_test.expected == assembler.binary_output);
                        }
                    }
                    catch (const std::exception& ex) {
                        if (current_test.negative_test) {
                            test_passed = true;
                        } else {
                            test_passed = false;
                            fail_msg = std::format("FAILED with exception: {}\n", ex.what());
                        }
                    }

                    total_processed.fetch_add(1, std::memory_order_relaxed);

                    if (test_passed) {
                        int current_passed = ++passed_count;
                        std::lock_guard<std::mutex> console_lock(console_mutex);
                        std::cout << std::format("{} {}PASSED: {:6}{}", 
                            es.column(col), 
                            es.gr(es.BRIGHT_GREEN_FOREGROUND), 
                            current_passed, 
                            es.ERASE_CURSOR_EOL);
                    } else {
                        int current_failed = ++failed_count;
                        overall_passed.store(false, std::memory_order_relaxed);

                        std::lock_guard<std::mutex> console_lock(console_mutex);
                        std::cout << std::format("\n{} FAILED\n{}\n", 
                            (current_test.negative_test ? "negative" : "positive"), 
                            current_test.source_code);

                        std::cout << std::format("{}{} PASSED: {:6} {}FAILED: {}{}", 
                            es.column(col), 
                            es.gr(es.BRIGHT_GREEN_FOREGROUND), 
                            passed_count.load(), 
                            es.gr(es.BRIGHT_RED_FOREGROUND), 
                            current_failed, 
                            es.ERASE_CURSOR_EOL);

                        error_ss << fail_msg;
                        this->source_code = current_test.source_code;

                        if (exit_on_fail) {
                            stop_requested.store(true, std::memory_order_relaxed);
                            cv_producer.notify_one();
                            cv_workers.notify_all();
                            return;
                        }
                    }
                }
            });
        }

		// Join producer and worker threads
		if (producer.joinable()) producer.join();
		for (auto& w : workers) {
    		if (w.joinable()) w.join();
		}

		// Rethrow and catch the exception back on the main thread
		if (producer_exception) {
        	std::rethrow_exception(producer_exception);
		}
	}
};