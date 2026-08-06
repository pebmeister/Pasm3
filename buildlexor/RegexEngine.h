#pragma once
// written by Paul Baxter

#include <iostream>
#include <vector>
#include <string>
#include <memory>
#include <set>
#include <map>
#include <tuple>
#include <stdexcept>
#include <cctype>
#include <algorithm>
#include <sstream>
#include <initializer_list>

// ==============================================================
// 1. DATA STRUCTURES & NFA BUILDER
// ==============================================================

struct CharRange {
	unsigned char low;
	unsigned char high;
};

struct NFAState {
	int id;
	bool is_accept = false;
	int token_id = 0;
	bool anchor_bol = false; // Requires column 1 / start of line
	bool anchor_eol = false; // Requires end of line / EOF
	std::vector<NFAState*> epsilon_transitions;
	struct Transition {
		std::vector<CharRange> ranges;
		NFAState* target;
	};
	std::vector<Transition> transitions;
};

struct NFAFragment {
	NFAState* start = nullptr;
	NFAState* end = nullptr;
};

class NFABuilder {
private:
	std::vector<std::unique_ptr<NFAState>> all_states_;
	int next_id_ = 0;
	bool case_insensitive_ = false;

	char parseClassChar(const std::string& pattern, size_t& pos) {
    	if (pos >= pattern.length()) {
        	return '\0';
		}

    	char c = pattern[pos++];
   		const size_t len = pattern.length();

    	if (c == '\\' && pos < len) {
        	char escaped = pattern[pos++];

        	switch (escaped) {
            	case 'n': return '\n';
            	case 'r': return '\r';
            	case 't': return '\t';
            	case 'f': return '\f';
            	case 'v': return '\v';
            	case 'a': return '\a';

            	case 'x': {
                	if (pos < len && std::isxdigit(static_cast<unsigned char>(pattern[pos]))) {
                    	auto hexDigit = [](char ch) -> int {
                        	if (ch >= '0' && ch <= '9') return ch - '0';
                        	if (ch >= 'a' && ch <= 'f') return ch - 'a' + 10;
                        	if (ch >= 'A' && ch <= 'F') return ch - 'A' + 10;
                       			return 0;
                    	};

                    	int val = hexDigit(pattern[pos++]);
                    	// Optional second hex digit (e.g., \x93)
                    	if (pos < len && std::isxdigit(static_cast<unsigned char>(pattern[pos]))) {
                        	val = (val << 4) | hexDigit(pattern[pos++]);
                    	}
                    	return static_cast<char>(val);
                	}
                	throw std::runtime_error("Invalid hex escape sequence");
            	}

            	default: {
                	// Octal escape sequences (\0 to \377 / 1 to 3 digits)
                	if (escaped >= '0' && escaped <= '7') {
                    	int val = escaped - '0';
                    	int digits = 1;
                    	while (digits < 3 && pos < len && pattern[pos] >= '0' && pattern[pos] <= '7') {
                        	val = (val << 3) | (pattern[pos++] - '0');
                        	digits++;
                    	}
                    	if (val > 255) {
                        	throw std::runtime_error("Octal escape sequence out of range (> 255)");
                    	}
                    	return static_cast<char>(val);
                	}

                	return escaped; // Handles '\]', '\-', '\\', etc.
            	}
        	}
    	}
    	return c;
	}

	std::vector<CharRange> applyCaseInsensitivity(const std::vector<CharRange>& input_ranges) {
		if (!case_insensitive_) return input_ranges;
		std::set<unsigned char> bytes;
		for (const auto& r : input_ranges) {
			for (int ch = r.low; ch <= r.high; ++ch) {
				unsigned char b = static_cast<unsigned char>(ch);
				bytes.insert(b);
				if (std::isalpha(b)) {
					bytes.insert(static_cast<unsigned char>(std::tolower(b)));
					bytes.insert(static_cast<unsigned char>(std::toupper(b)));
				}
			}
		}
		std::vector<CharRange> result;
		if (bytes.empty()) return result;
		auto it = bytes.begin();
		unsigned char range_start = *it, prev = *it;
		it++;
		for (; it != bytes.end(); ++it) {
			if (*it == prev + 1) prev = *it;
			else {
				result.push_back({ range_start, prev });
				range_start = *it;
				prev = *it;
			}
		}
		result.push_back({ range_start, prev });
		return result;
	}

public:
	NFAState* createState() {
		auto state = std::make_unique<NFAState>();
		state->id = next_id_++;
		NFAState* ptr = state.get();
		all_states_.push_back(std::move(state));
		return ptr;
	}

	NFAFragment makeRange(const std::vector<CharRange>& ranges, bool apply_case = true) {
		NFAState* start = createState();
		NFAState* end = createState();
		std::vector<CharRange> final_ranges = apply_case ? applyCaseInsensitivity(ranges) : ranges;
		start->transitions.push_back({ final_ranges, end });
		return { start, end };
	}

	NFAFragment makeConcat(const NFAFragment& first, const NFAFragment& second) {
		first.end->epsilon_transitions.push_back(second.start);
		return { first.start, second.end };
	}

	NFAFragment makeOr(const NFAFragment& first, const NFAFragment& second) {
		NFAState* start = createState();
		NFAState* end = createState();
		start->epsilon_transitions.push_back(first.start);
		start->epsilon_transitions.push_back(second.start);
		first.end->epsilon_transitions.push_back(end);
		second.end->epsilon_transitions.push_back(end);
		return { start, end };
	}

	NFAFragment makeStar(const NFAFragment& frag) {
		NFAState* start = createState();
		NFAState* end = createState();
		start->epsilon_transitions.push_back(frag.start);
		start->epsilon_transitions.push_back(end);
		frag.end->epsilon_transitions.push_back(frag.start);
		frag.end->epsilon_transitions.push_back(end);
		return { start, end };
	}

	NFAFragment makePlus(const NFAFragment& frag) {
		NFAState* start = createState();
		NFAState* end = createState();
		start->epsilon_transitions.push_back(frag.start);
		frag.end->epsilon_transitions.push_back(frag.start);
		frag.end->epsilon_transitions.push_back(end);
		return { start, end };
	}

	NFAFragment makeOptional(const NFAFragment& frag) {
		NFAState* start = createState();
		NFAState* end = createState();
		start->epsilon_transitions.push_back(frag.start);
		start->epsilon_transitions.push_back(end);
		frag.end->epsilon_transitions.push_back(end);
		return { start, end };
	}

	NFAFragment buildFromRegex(const std::string& pattern, bool case_insensitive = false) {
		case_insensitive_ = case_insensitive;
		size_t pos = 0;
		NFAFragment frag = parseExpression(pattern, pos);
		if (pos < pattern.size()) throw std::runtime_error("Unexpected trailing char");
		return frag;
	}

private:
	NFAFragment parseExpression(const std::string& pat, size_t& pos) {
		
		NFAFragment left = parseConcat(pat, pos);
		while (pos < pat.size() && pat[pos] == '|') {
			pos++;
			left = makeOr(left, parseConcat(pat, pos));
		}
		return left;
	}

	NFAFragment parseConcat(const std::string& pat, size_t& pos) {
		std::vector<NFAFragment> terms;
		while (pos < pat.size() && pat[pos] != '|' && pat[pos] != ')') {
			terms.push_back(parseQuantifiedAtom(pat, pos));
		}
		if (terms.empty()) {
			NFAState* s = createState();
			NFAState* e = createState();
			s->epsilon_transitions.push_back(e);
			return { s, e };
		}
		NFAFragment res = terms[0];
		for (size_t i = 1; i < terms.size(); ++i) res = makeConcat(res, terms[i]);
		return res;
	}

	NFAFragment parseQuantifiedAtom(const std::string& pat, size_t& pos) {
		size_t atom_start = pos;
		NFAFragment frag = parseAtom(pat, pos);
		if (pos >= pat.size()) return frag;
		char c = pat[pos];
		if (c == '*') {
			pos++;
			return makeStar(frag);
		}
		if (c == '+') {
			pos++;
			return makePlus(frag);
		}
		if (c == '?') {
			pos++;
			return makeOptional(frag);
		}
		if (c == '{') {
			pos++;
			size_t close = pat.find('}', pos);
			std::string r_str = pat.substr(pos, close - pos);
			pos = close + 1;
			int min_rep = 0, max_rep = 0;
			size_t comma = r_str.find(',');
			if (comma == std::string::npos) min_rep = max_rep = std::stoi(r_str);
			else {
				min_rep = std::stoi(r_str.substr(0, comma));
				std::string max_s = r_str.substr(comma + 1);
				max_rep = max_s.empty() ? -1 : std::stoi(max_s);
			}
			std::vector<NFAFragment> chain;
			for (int i = 0; i < min_rep; ++i) {
				size_t p = atom_start;
				chain.push_back(parseAtom(pat, p));
			}
			if (max_rep == -1) {
				size_t p = atom_start;
				chain.push_back(makeStar(parseAtom(pat, p)));
			}
			else {
				for (int i = min_rep; i < max_rep; ++i) {
					size_t p = atom_start;
					chain.push_back(makeOptional(parseAtom(pat, p)));
				}
			}
			if (chain.empty()) {
				NFAState* s = createState();
				NFAState* e = createState();
				s->epsilon_transitions.push_back(e);
				return { s, e };
			}
			NFAFragment res = chain[0];
			for (size_t i = 1; i < chain.size(); ++i) res = makeConcat(res, chain[i]);
			return res;
		}
		return frag;
	}

	NFAFragment parseAtom(const std::string& pat, size_t& pos) {

		char c = pat[pos];
		if (c == '(') {
			pos++;
			NFAFragment inner = parseExpression(pat, pos);
			pos++; // consume ')'
			return inner;
		}
		if (c == '[') return parseCharacterClass(pat, pos);
		
		// Fixed: dot handling with pos++ and clean range syntax
		if (c == '.') {
			pos++;
			return makeRange({
				{0, static_cast<unsigned char>('\n' - 1)},
				{static_cast<unsigned char>('\n' + 1), 255}
			}, false);
		}

		if (c == '^') {
			pos++;
			return makeRange({ {'^', '^'} });
		}
		if (c == '$') {
			pos++;
			return makeRange({ {'$', '$'} });
		}

		if (c == '\\') {
			pos++;
			char e = pat[pos++];
			if (e == 'd') return makeRange({ {'0', '9'} });
			if (e == 'w') return makeRange({ {'a', 'z'}, {'A', 'Z'}, {'0', '9'}, {'_', '_'} });
			if (e == 's') return makeRange({ {' ', ' '}, {'\t', '\r'} });
			if (e == 'D') return makeRange({ 
			        {0, static_cast<unsigned char>('0'-1)},
			        {static_cast<unsigned char>('9'+1), static_cast<unsigned char>(255)}
			});
			if (e == 'W') return makeRange({
			        {0, static_cast<unsigned char>('0'-1)},
			        {static_cast<unsigned char>('9'+1), static_cast<unsigned char>('A'-1)},
			        {static_cast<unsigned char>('Z'+1), static_cast<unsigned char>('_'-1)},
			        {static_cast<unsigned char>('_'+1), static_cast<unsigned char>('a'-1)},
			        {static_cast<unsigned char>('z'+1), static_cast<unsigned char>(255)}
			});
			if (e == 'S') return makeRange({ 
			        {0, static_cast<unsigned char>('\t'-1)},
			        {static_cast<unsigned char>('\r'+1), static_cast<unsigned char>(' '-1)},
			        {static_cast<unsigned char>(' '+1), static_cast<unsigned char>(255)}
			});

			// let parseClassChar handle it for consistant C++ escape sequences
			pos--;
			char r = parseClassChar(pat, pos);
			return makeRange({ {static_cast<unsigned char>(r), static_cast<unsigned char>(r)} });
		}
		pos++;
		return makeRange({ {static_cast<unsigned char>(c), static_cast<unsigned char>(c)} });
	}

    NFAFragment parseCharacterClass(const std::string& pat, size_t& pos) {
        pos++;
        bool negated = false;
        if (pos < pat.size() && pat[pos] == '^') {
            negated = true;
            pos++;
        }
        
        std::set<unsigned char> inc;
        
        while (pos < pat.size() && pat[pos] != ']') {
            // 1. Read the start char, translating \n, \t, etc. automatically
            unsigned char s_c = parseClassChar(pat, pos);
            
            // 2. Check for a range indicator (e.g., a-z)
            if (pos + 1 < pat.size() && pat[pos] == '-' && pat[pos + 1] != ']') {
                pos++; // consume the '-'
                
                // 3. Read the end char, translating escapes here too
                unsigned char e_c = parseClassChar(pat, pos);
                
                for (int ch = s_c; ch <= e_c; ++ch) {
                    inc.insert(static_cast<unsigned char>(ch));
                }
            } else {
                inc.insert(s_c);
            }
        }
        pos++; // consume ']'

        if (case_insensitive_) {
            std::set<unsigned char> exp;
            for (unsigned char ch : inc) {
                exp.insert(ch);
                if (std::isalpha(ch)) {
                    exp.insert(std::tolower(ch));
                    exp.insert(std::toupper(ch));
                }
            }
            inc = std::move(exp);
        }
        
        if (negated) {
            std::set<unsigned char> inv;
            for (int ch = 0; ch < 256; ++ch) {
                if (inc.find(ch) == inc.end()) inv.insert(ch);
            }
            inc = std::move(inv);
        }

		std::vector<CharRange> ranges;
        if (!inc.empty()) {
            auto it = inc.begin();
            unsigned char rs = static_cast<unsigned char>(*it);
            unsigned char prev = static_cast<unsigned char>(*it);
            it++;

            for (; it != inc.end(); ++it) {
                unsigned char curr = static_cast<unsigned char>(*it);
                if (curr == prev + 1) {
                    prev = curr;
                } else {
                    ranges.push_back({ rs, prev });
                    rs = curr;
                    prev = curr;
                }
            }
            ranges.push_back({ rs, prev });
        }

        return makeRange(ranges, false);
    }
}; // <-- THIS BRACE WAS MISSING

// ==============================================================
// 2. DFA CONVERSION
// ==============================================================

struct DFAState {
	int id;
	bool is_accept = false;
	int token_id = 0;
	bool anchor_bol = false;
	bool anchor_eol = false;
	std::map<unsigned char, int> transitions;
};

class DFAConverter {
private:
	std::vector<std::unique_ptr<DFAState>> dfa_states_;

	std::set<NFAState*> epsilonClosure(const std::set<NFAState*>& states) {
		std::set<NFAState*> closure = states;
		std::vector<NFAState*> stack(states.begin(), states.end());
		while (!stack.empty()) {
			NFAState* s = stack.back();
			stack.pop_back();
			for (NFAState* next : s->epsilon_transitions) {
				if (closure.insert(next).second) stack.push_back(next);
			}
		}
		return closure;
	}

public:
	std::vector<DFAState*> convertNFA(NFAState* master_start) {
		dfa_states_.clear();

		auto dead_state = std::make_unique<DFAState>();
		dead_state->id = 0;
		dfa_states_.push_back(std::move(dead_state));

		std::map<std::set<NFAState*>, int> dfa_map;
		std::vector<std::set<NFAState*>> worklist;

		std::set<NFAState*> start_closure = epsilonClosure({master_start});
		auto root = std::make_unique<DFAState>();
		root->id = 1;
		dfa_map[start_closure] = 1;
		worklist.push_back(start_closure);
		dfa_states_.push_back(std::move(root));

		while (!worklist.empty()) {
			std::set<NFAState*> current_nfa_set = worklist.back();
			worklist.pop_back();
			int current_dfa_id = dfa_map[current_nfa_set];

			for (NFAState* nfa_s : current_nfa_set) {
				if (nfa_s->is_accept) {
					if (!dfa_states_[current_dfa_id]->is_accept || nfa_s->token_id < dfa_states_[current_dfa_id]->token_id) {
						dfa_states_[current_dfa_id]->is_accept = true;
						dfa_states_[current_dfa_id]->token_id = nfa_s->token_id;
						dfa_states_[current_dfa_id]->anchor_bol = nfa_s->anchor_bol;
						dfa_states_[current_dfa_id]->anchor_eol = nfa_s->anchor_eol;
					}
				}
			}

			for (int byte_val = 0; byte_val < 256; ++byte_val) {
				std::set<NFAState*> move_set;
				for (NFAState* nfa_s : current_nfa_set) {
					for (const auto& transition : nfa_s->transitions) {
						bool matches = false;
						for (const auto& range : transition.ranges) {
							if (byte_val >= range.low && byte_val <= range.high) {
								matches = true;
								break;
							}
						}
						if (matches) move_set.insert(transition.target);
					}
				}

				if (move_set.empty()) continue;

				std::set<NFAState*> target_closure = epsilonClosure(move_set);
				if (dfa_map.find(target_closure) == dfa_map.end()) {
					int new_id = dfa_states_.size();
					dfa_map[target_closure] = new_id;
					auto new_dfa = std::make_unique<DFAState>();
					new_dfa->id = new_id;
					dfa_states_.push_back(std::move(new_dfa));
					worklist.push_back(target_closure);
				}
				dfa_states_[current_dfa_id]->transitions[byte_val] = dfa_map[target_closure];
			}
		}
		std::vector<DFAState*> result;
		for (const auto& s : dfa_states_) result.push_back(s.get());
		return result;
	}
};

// ==============================================================
// 3. EQUIVALENCE CLASSES & HOPCROFT MINIMIZATION
// ==============================================================

struct EquivalenceClassResult {
	int byte_to_class[256];
	int num_classes;
	std::vector<std::vector<int>> compressed_transitions;
};

inline EquivalenceClassResult computeClasses(const std::vector<DFAState*>& dfa) {
	EquivalenceClassResult res;
	std::vector<std::vector<int>> partition(dfa.size(), std::vector<int>(256, 0));

	for (size_t s = 0; s < dfa.size(); ++s) {
		for (const auto& [byte_val, target] : dfa[s]->transitions) {
			partition[s][byte_val] = target;
		}
	}

	std::map<std::vector<int>, int> class_map;
	int next_class_id = 0;

	for (int b = 0; b < 256; ++b) {
		std::vector<int> behavior(dfa.size());
		for (size_t s = 0; s < dfa.size(); ++s) behavior[s] = partition[s][b];
		if (class_map.find(behavior) == class_map.end()) class_map[behavior] = next_class_id++;
		res.byte_to_class[b] = class_map[behavior];
	}
	res.num_classes = next_class_id;
	res.compressed_transitions.assign(dfa.size(), std::vector<int>(res.num_classes, 0));

	for (int b = 0; b < 256; ++b) {
		int cls = res.byte_to_class[b];
		for (size_t s = 0; s < dfa.size(); ++s) res.compressed_transitions[s][cls] = partition[s][b];
	}
	return res;
}

inline std::vector<std::unique_ptr<DFAState>> minimizeDFA(const std::vector<DFAState*>& states, const EquivalenceClassResult& eq) {
	if (states.size() <= 2) {
		std::vector<std::unique_ptr<DFAState>> copy;
		for (const auto* s : states) {
			auto n = std::make_unique<DFAState>();
			*n = *s;
			copy.push_back(std::move(n));
		}
		return copy;
	}

	int num_states = states.size();
	std::map<std::tuple<bool, int, bool, bool>, std::set<int>> initial_groups;
	for (int i = 1; i < num_states; ++i) {
		initial_groups[{
			states[i]->is_accept,
			states[i]->token_id,
			states[i]->anchor_bol,
			states[i]->anchor_eol
		}].insert(i);
	}

	std::vector<std::set<int>> partitions = {{0}};
	for (auto& [key, group] : initial_groups) partitions.push_back(group);

	std::vector<int> s_to_p(num_states, 0);
	auto updateMap = [&]() {
		for (size_t p = 0; p < partitions.size(); ++p) {
			for (int s : partitions[p]) s_to_p[s] = p;
		}
	};
	updateMap();

	std::vector<int> worklist;
	for (size_t p = 1; p < partitions.size(); ++p) worklist.push_back(p);

	while (!worklist.empty()) {
		int act_idx = worklist.back();
		worklist.pop_back();
		std::set<int> active_set = partitions[act_idx];

		for (int cls = 0; cls < eq.num_classes; ++cls) {
			std::set<int> preds;
			for (int s = 0; s < num_states; ++s) {
				if (active_set.count(eq.compressed_transitions[s][cls])) preds.insert(s);
			}
			if (preds.empty()) continue;

			size_t num_p = partitions.size();
			for (size_t p = 0; p < num_p; ++p) {
				std::set<int> inters, diff;
				for (int s : partitions[p]) {
					if (preds.count(s)) inters.insert(s);
					else diff.insert(s);
				}
				if (!inters.empty() && !diff.empty()) {
					partitions[p] = inters;
					partitions.push_back(diff);
					int new_p = partitions.size() - 1;
					updateMap();
					auto wl_it = std::find(worklist.begin(), worklist.end(), p);
					if (wl_it != worklist.end()) worklist.push_back(new_p);
					else {
						if (inters.size() <= diff.size()) worklist.push_back(p);
						else worklist.push_back(new_p);
					}
				}
			}
		}
	}

	std::vector<int> p_to_new(partitions.size(), -1);
	p_to_new[0] = 0;
	p_to_new[s_to_p[1]] = 1;
	int next_id = 2;
	for (size_t p = 0; p < partitions.size(); ++p) {
		if (p_to_new[p] == -1) p_to_new[p] = next_id++;
	}

	std::vector<std::unique_ptr<DFAState>> min_dfa(partitions.size());
	for (size_t p = 0; p < partitions.size(); ++p) {
		int n_id = p_to_new[p];
		int old_s = *partitions[p].begin();
		auto n_state = std::make_unique<DFAState>();
		n_state->id = n_id;
		n_state->is_accept = states[old_s]->is_accept;
		n_state->token_id = states[old_s]->token_id;
		n_state->anchor_bol = states[old_s]->anchor_bol;
		n_state->anchor_eol = states[old_s]->anchor_eol;

		for (auto& [b_val, o_targ] : states[old_s]->transitions) {
			int t_new = p_to_new[s_to_p[o_targ]];
			if (t_new != 0) n_state->transitions[b_val] = t_new;
		}
		min_dfa[n_id] = std::move(n_state);
	}
	return min_dfa;
}

// ==============================================================
// 4. CODE GENERATOR & FACADE
// ==============================================================

class RegexCompiler {
private:
	struct Rule {
		std::string pattern;
		int id;
		bool case_insensitive;
		bool anchor_bol = false;
		bool anchor_eol = false;
	};
	std::vector<Rule> rules;

public:
	struct RuleSpec {
		std::string pattern;
		int token_id;
		bool case_insensitive = false;
		bool anchor_bol = false;
		bool anchor_eol = false;
	};

	void addRule(const std::string& pattern, int token_id, bool case_insensitive = false, bool anchor_bol = false, bool anchor_eol = false) {
		rules.push_back({pattern, token_id, case_insensitive, anchor_bol, anchor_eol});
	}

	void addRules(std::initializer_list<RuleSpec> rule_list) {
		for (const auto& rule : rule_list) {
			addRule(rule.pattern, rule.token_id, rule.case_insensitive, rule.anchor_bol, rule.anchor_eol);
		}
	}

	std::string generateCppClass(const std::string& class_name = "Tokenizer") {
		NFABuilder builder;
		NFAState* master = builder.createState();
		for (const auto& r : rules) {
			std::string pat = r.pattern;
			bool bol = r.anchor_bol;
			bool eol = r.anchor_eol;

			// Extract leading '^' anchor if present
			if (!pat.empty() && pat.front() == '^') {
				bol = true;
				pat.erase(0, 1);
			}
			// Extract trailing '$' anchor if present (and not escaped \$)
			if (pat.size() >= 1 && pat.back() == '$' && (pat.size() < 2 || pat[pat.size() - 2] != '\\')) {
				eol = true;
				pat.pop_back();
			}

			NFAFragment frag = builder.buildFromRegex(pat, r.case_insensitive);
			frag.end->is_accept = true;
			frag.end->token_id = r.id;
			frag.end->anchor_bol = bol;
			frag.end->anchor_eol = eol;
			master->epsilon_transitions.push_back(frag.start);
		}

		DFAConverter converter;
		std::vector<DFAState*> raw = converter.convertNFA(master);
		EquivalenceClassResult eq = computeClasses(raw);
		auto min_owners = minimizeDFA(raw, eq);
		std::vector<DFAState*> min_dfa;
		for(auto& s : min_owners) min_dfa.push_back(s.get());

		std::stringstream ss;
		ss << "/**\n * Auto-Generated Tokenizer Class\n * Powered by Thompson NFA + Powerset DFA + Hopcroft Minimization\n */\n";
		ss << "#pragma once\n#include <string>\n#include <vector>\n\n";
		ss << "class " << class_name << " {\n";
		ss << "private:\n";

		ss << "    static inline constexpr int byte_to_class[256] = {\n        ";
		for (int i = 0; i < 256; ++i) {
			ss << eq.byte_to_class[i] << (i < 255 ? ", " : "");
			if ((i + 1) % 16 == 0 && i < 255) ss << "\n        ";
		}
		ss << "\n    };\n\n";

		int num_states = min_dfa.size();
		ss << "    static inline constexpr int transition_table[" << num_states << "][" << eq.num_classes << "] = {\n";
		for (int s = 0; s < num_states; ++s) {
			ss << "        {";
			for (int c = 0; c < eq.num_classes; ++c) {
				int target = 0;
				for (int b = 0; b < 256; ++b) {
					if (eq.byte_to_class[b] == c) {
						if (min_dfa[s]->transitions.count(b)) target = min_dfa[s]->transitions[b];
						break;
					}
				}
				ss << target << (c < eq.num_classes - 1 ? ", " : "");
			}
			ss << "}" << (s < num_states - 1 ? ",\n" : "\n");
		}
		ss << "    };\n\n";

		ss << "    static inline constexpr int accept_table[" << num_states << "] = {\n        ";
		for (int s = 0; s < num_states; ++s) {
			ss << (min_dfa[s]->is_accept ? min_dfa[s]->token_id : 0) << (s < num_states - 1 ? ", " : "");
			if ((s + 1) % 16 == 0 && s < num_states - 1) ss << "\n        ";
		}
		ss << "\n    };\n\n";

		// Anchor Tables
		ss << "    static inline constexpr bool anchor_bol_table[" << num_states << "] = {\n        ";
		for (int s = 0; s < num_states; ++s) {
			ss << (min_dfa[s]->is_accept && min_dfa[s]->anchor_bol ? "true" : "false") << (s < num_states - 1 ? ", " : "");
			if ((s + 1) % 16 == 0 && s < num_states - 1) ss << "\n        ";
		}
		ss << "\n    };\n\n";

		ss << "    static inline constexpr bool anchor_eol_table[" << num_states << "] = {\n        ";
		for (int s = 0; s < num_states; ++s) {
			ss << (min_dfa[s]->is_accept && min_dfa[s]->anchor_eol ? "true" : "false") << (s < num_states - 1 ? ", " : "");
			if ((s + 1) % 16 == 0 && s < num_states - 1) ss << "\n        ";
		}
		ss << "\n    };\n\n";

		ss << "public:\n";
		ss << "    struct Token {\n";
		ss << "        int id;\n";
		ss << "        std::string text;\n";
		ss << "        size_t position;\n";
		ss << "        size_t line;\n";
		ss << "        size_t col;\n\n";
 
	    ss << "        [[nodiscard]] bool is(int k) const {return id == k;}\n";
	    ss << "        [[nodiscard]] bool isNot(int k) const {return id != k;}\n";
	    ss << "        [[nodiscard]] bool is(std::string_view s) const {return s == text;}\n";
	    ss << "        [[nodiscard]] bool isNot(std::string_view s) const {return s != text;}\n";
		ss << "    };\n\n";

		ss << "    static std::vector<Token> tokenize(const std::string& input) {\n";
		ss << "        std::vector<Token> tokens;\n";
		ss << "        size_t pos = 0;\n";
		ss << "        size_t current_line = 1;\n";
		ss << "        size_t current_column = 1;\n\n";

		ss << "        while (pos < input.size()) {\n";
		ss << "            size_t start_pos = pos;\n";
		ss << "            int current_state = 1;\n";
		ss << "            int last_accept_state = 0;\n";
		ss << "            size_t last_accept_pos = start_pos;\n\n";

		ss << "            while (pos < input.size()) {\n";
		ss << "                unsigned char byte = static_cast<unsigned char>(input[pos]);\n";
		ss << "                current_state = transition_table[current_state][byte_to_class[byte]];\n";
		ss << "                if (current_state == 0) break;\n";
		ss << "                pos++;\n";
		ss << "                if (accept_table[current_state] > 0) {\n";
		ss << "                    bool bol_ok = !anchor_bol_table[current_state] || (current_column == 1);\n";
		ss << "                    bool eol_ok = !anchor_eol_table[current_state] || (pos >= input.size() || input[pos] == '\\n' || input[pos] == '\\r');\n";
		ss << "                    if (bol_ok && eol_ok) {\n";
		ss << "                        last_accept_state = current_state;\n";
		ss << "                        last_accept_pos = pos;\n";
		ss << "                    }\n";
		ss << "                }\n";
		ss << "            }\n\n";

		ss << "            if (last_accept_state > 0) {\n";
		ss << "                std::string lexeme = input.substr(start_pos, last_accept_pos - start_pos);\n";
		ss << "                tokens.push_back({accept_table[last_accept_state], lexeme, start_pos, current_line, current_column});\n";
		ss << "                pos = last_accept_pos;\n";
		ss << "                \n";
		ss << "                // Advance line/column state based on the matched lexeme\n";
		ss << "                for (char c : lexeme) {\n";
		ss << "                    if (c == '\\n') { current_line++; current_column = 1; }\n";
		ss << "                    else { current_column++; }\n";
		ss << "                }\n";
		ss << "            } else {\n";
		ss << "                // Fallback for unmatched character\n";
		ss << "                char bad_char = input[start_pos];\n";
		ss << "                tokens.push_back({-2, std::string(1, bad_char), start_pos, current_line, current_column});\n";
		ss << "                pos = start_pos + 1;\n";
		ss << "                \n";
		ss << "                // Advance state for the single bad character\n";
		ss << "                if (bad_char == '\\n') { current_line++; current_column = 1; }\n";
		ss << "                else { current_column++; }\n";
		ss << "            }\n";
		ss << "        }\n";
		ss << "        return tokens;\n";
		ss << "    }\n";
		ss << "};\n";

		return ss.str();
	}
};
