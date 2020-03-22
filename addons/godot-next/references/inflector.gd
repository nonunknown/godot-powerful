# author: xdgamestudios (adapted from C# .NET Humanizer, licensed under MIT)
# license: MIT
# description: Provides inflection tools to pluralize and singularize strings.
# todo: Add more functionality
# usage:
# - Creating Inflector:
#     inflector = Inflector.new() # new inflector with empty vocabulary
#     inflector = Inflector.new(vocabulary) # new inflector with vocabulary
#     Note:
#     - Inflector with no vocabulary will not be able to apply convertion out-of-the-box.
# - Creating Vocabulary:
#     vocabulary = Inflector.Vocabulary.new() # creates new empty vocabulary
#     vocabulary = Inflector.Vocabulary.build_default_vocabulary()
#     Note:
#     - Empty vocabulary can be manually configured with custom rules.
#     - Default vocabulary will apply convertions for english language.
# - Get Vocabulary:
#     vocabulary = inflector.get_vocabulary() # reference to the vocabulary used by the inflector.
# - Add Rules:
#     vocabulary.add_plural(rule, replacement) # adds convertion rule to plural
#     vocabulary.add_singular(rule, replacement) # adds convertion rule to singular
#     vocabulary.add_irregular(rule, replacement) # adds irregular convertion
#     vocabulary.add_uncountable(word) # add unconvertable word
#     Note:
#     - 'rule' is a String with regex syntax.
#     - 'replacement' is a String with regex systax.
# - Using Inflector:
#     inflector.pluralize(word, p_force = false) # returns the plural of the word
#     inflector.singularize(word, p_force = false) # returns the singular of the word
#     Note:
#     - If the first parameter's state is unknown, use 'p_force = true' to force an unknown term into the desired state.
tool
extends Reference
class_name Inflector

##### CLASSES #####

class Rule extends Reference:
	
	##### PROPERTIES #####
	
	var _regex: RegEx
	var _replacement: String
	
	##### NOTIFICATIONS #####
	
	func _init(p_rule: String, p_replacement: String) -> void:
		_regex = RegEx.new()
		#warning-ignore:return_value_discarded
		_regex.compile(p_rule)
		_replacement = p_replacement
	
	##### PUBLIC METHODS #####
	
	func apply(p_word: String):
		if not _regex.search(p_word):
			return null
		return _regex.sub(p_word, _replacement)

class Vocabulary extends Reference:
	
	##### PROPERTIES #####
	
	var _plurals: Array = [] setget, get_plurals
	var _singulars: Array = [] setget, get_singulars
	var _uncountables: Array = [] setget, get_uncountables
	
	##### PUBLIC METHODS #####
	
	func get_plurals() -> Array:
		return _plurals
	
	func get_singulars() -> Array:
		return _singulars
	
	func get_uncountables() -> Array:
		return _uncountables
	
	func add_plural(p_rule: String, p_replacement: String) -> void:
		_plurals.append(Rule.new(p_rule, p_replacement))
	
	func add_singular(p_rule: String, p_replacement: String) -> void:
		_singulars.append(Rule.new(p_rule, p_replacement))
	
	func add_irregular(p_singular: String, p_plural: String, p_match_ending: bool = true) -> void:
		if p_match_ending:
			var sfirst = p_singular[0]
			var pfirst = p_plural[0]
			var strimmed = p_singular.trim_prefix(sfirst)
			var ptrimmed = p_plural.trim_prefix(pfirst)
			add_plural("(" + sfirst + ")" + strimmed + "$", "$1" + ptrimmed)
			add_singular("(" + pfirst + ")" + ptrimmed + "$", "$1" + strimmed)
		else:
			add_plural("^%s$" % p_singular, p_plural)
			add_singular("^%s$" % p_plural, p_singular)
	
	func add_uncountable(p_word: String) -> void:
		_uncountables.append(p_word.to_lower())
	
	func is_uncountable(p_word: String) -> bool:
		return _uncountables.has(p_word.to_lower())
	
	static func build_default_vocabulary() -> Vocabulary:
		
		var vocabulary = Vocabulary.new()
		
		# plurals rules
		vocabulary._plurals = [
			Rule.new("$", "s"),
			Rule.new("s$", "s"),
			Rule.new("(ax|test)is$", "$1es"),
			Rule.new("(octop|vir|alumn|fung|cact|foc|hippopotam|radi|stimul|syllab|nucle)us$", "$1i"),
			Rule.new("(alias|bias|iris|status|campus|apparatus|virus|walrus|trellis)$", "$1es"),
			Rule.new("(buffal|tomat|volcan|ech|embarg|her|mosquit|potat|torped|vet)o$", "$1oes"),
			Rule.new("([dti])um$", "$1a"),
			Rule.new("sis$", "ses"),
			Rule.new("([lr])f$", "$1ves"),
			Rule.new("([^f])fe$", "$1ves"),
			Rule.new("(hive)$", "$1s"),
			Rule.new("([^aeiouy]|qu)y$", "$1ies"),
			Rule.new("(x|ch|ss|sh)$", "$1es"),
			Rule.new("(matr|vert|ind|d)ix|ex$", "$1ices"),
			Rule.new("([m|l])ouse$", "$1ice"),
			Rule.new("^(ox)$", "$1en"),
			Rule.new("(quiz)$", "$1zes"),
			Rule.new("(buz|blit|walt)z$", "$1zes"),
			Rule.new("(hoo|lea|loa|thie)f$", "$1ves"),
			Rule.new("(alumn|alg|larv|vertebr)a$", "$1ae"),
			Rule.new("(criteri|phenomen)on$", "$1a")
		]
		
		# singular rules
		vocabulary._singulars = [
			Rule.new("s$", ""),
			Rule.new("(n)ews$", "$1ews"),
			Rule.new("([dti])a$", "$1um"),
			Rule.new("(analy|ba|diagno|parenthe|progno|synop|the|ellip|empha|neuro|oa|paraly)ses$", "$1sis"),
			Rule.new("([^f])ves$", "$1fe"),
			Rule.new("(hive)s$", "$1"),
			Rule.new("(tive)s$", "$1"),
			Rule.new("([lr]|hoo|lea|loa|thie)ves$", "$1f"),
			Rule.new("(^zomb)?([^aeiouy]|qu)ies$", "$2y"),
			Rule.new("(s)eries$", "$1eries"),
			Rule.new("(m)ovies$", "$1ovie"),
			Rule.new("(x|ch|ss|sh)es$", "$1"),
			Rule.new("([m|l])ice$", "$1ouse"),
			Rule.new("(o)es$", "$1"),
			Rule.new("(shoe)s$", "$1"),
			Rule.new("(cris|ax|test)es$", "$1is"),
			Rule.new("(octop|vir|alumn|fung|cact|foc|hippopotam|radi|stimul|syllab|nucle)i$", "$1us"),
			Rule.new("(alias|bias|iris|status|campus|apparatus|virus|walrus|trellis)es$", "$1"),
			Rule.new("^(ox)en", "$1"),
			Rule.new("(matr|d)ices$", "$1ix"),
			Rule.new("(vert|ind)ices$", "$1ex"),
			Rule.new("(quiz)zes$", "$1"),
			Rule.new("(buz|blit|walt)zes$", "$1z"),
			Rule.new("(alumn|alg|larv|vertebr)ae$", "$1a"),
			Rule.new("(criteri|phenomen)a$", "$1on"),
			Rule.new("([b|r|c]ook|room|smooth)ies$", "$1ie")
		]
		
		# irregular rules
		vocabulary.add_irregular("person", "people")
		vocabulary.add_irregular("man", "men")
		vocabulary.add_irregular("human", "humans")
		vocabulary.add_irregular("child", "children")
		vocabulary.add_irregular("sex", "sexes")
		vocabulary.add_irregular("move", "moves")
		vocabulary.add_irregular("goose", "geese")
		vocabulary.add_irregular("wave", "waves")
		vocabulary.add_irregular("die", "dice")
		vocabulary.add_irregular("foot", "feet")
		vocabulary.add_irregular("tooth", "teeth")
		vocabulary.add_irregular("curriculum", "curricula")
		vocabulary.add_irregular("database", "databases")
		vocabulary.add_irregular("zombie", "zombies")
		vocabulary.add_irregular("personnel", "personnel")
		
		vocabulary.add_irregular("is", "are", true)
		vocabulary.add_irregular("that", "those", true)
		vocabulary.add_irregular("this", "these", true)
		vocabulary.add_irregular("bus", "buses", true)
		vocabulary.add_irregular("staff", "staff", true)
		
		#  uncountables
		vocabulary._uncountables = [
			"equipment",
			"information",
			"corn",
			"milk",
			"rice",
			"money",
			"species",
			"series",
			"fish",
			"sheep",
			"deer",
			"aircraft",
			"oz",
			"tsp",
			"tbsp",
			"ml",
			"l",
			"water",
			"waters",
			"semen",
			"sperm",
			"bison",
			"grass",
			"hair",
			"mud",
			"elk",
			"luggage",
			"moose",
			"offspring",
			"salmon",
			"shrimp",
			"someone",
			"swine",
			"trout",
			"tuna",
			"corps",
			"scissors",
			"means",
			"mail"
		]
		
		return vocabulary

##### PROPERTIES #####

var _vocabulary: Vocabulary setget, get_vocabulary

##### NOTIFICATIONS #####

func _init(p_vocabulary = null) -> void:
	if not p_vocabulary:
		p_vocabulary = Vocabulary.build_default_vocabulary()
	else:
		_vocabulary = p_vocabulary

##### PUBLIC METHODS #####

func get_vocabulary() -> Vocabulary:
	return _vocabulary

func pluralize(p_word: String, p_force: bool = false) -> String:
	var result = apply_rules(_vocabulary.get_plurals(), p_word)
	
	if not p_force:
		return result
	
	var as_singular = apply_rules(_vocabulary.get_singulars(), p_word)
	var as_singular_as_plural = apply_rules(_vocabulary.get_plurals(), as_singular)
	
	if as_singular and as_singular != p_word and as_singular + "s" != p_word and as_singular_as_plural == p_word and result != p_word:
		return p_word
	
	return result

func singularize(p_word: String, p_force: bool = false) -> String:
	var result = apply_rules(_vocabulary.get_singulars(), p_word)
	
	if not p_force:
		return result
	
	var as_plural = apply_rules(_vocabulary.get_plurals(), p_word)
	var as_plural_as_singular = apply_rules(_vocabulary.get_singulars(), as_plural)
	
	if as_plural and p_word + "s" != as_plural and as_plural_as_singular == p_word and result != p_word:
		return p_word
	
	return result

func apply_rules(p_rules: Array, p_word: String):
	if not p_word:
		return null

	if _vocabulary.is_uncountable(p_word):
		return p_word
	
	var result = p_word
	for i in range(len(p_rules) - 1, -1, -1):
		result = p_rules[i].apply(p_word)
		if result:
			break
	
	return result
