#!/bin/bash

## core definitions
if [ -z "$PM_ROOT_DIR" ]; then
    if [ -d "$HOME/packages" ]; then
        export PM_ROOT_DIR="$HOME/packages"
    elif [ -d "$HOME/pm" ]; then
        export PM_ROOT_DIR="$HOME/pm"
    else
        echo "export PM_ROOT_DIR in your shell profile"
        exit 1
    fi
fi
export PM_CONSTITUTION_LOC="$PM_ROOT_DIR/.internals/constitution.sh"
export PM_DISTRIBUTIONS_DIR="$PM_ROOT_DIR/distributions"
export PM_CONFIGURATIONS_DIR="$PM_ROOT_DIR/configuration"
export PM_SOURCES_DIR="$PM_ROOT_DIR/sources"
export PM_BUILDS_DIR="$PM_ROOT_DIR/builds"
export PM_STORES_DIR="$PM_ROOT_DIR/stores"
export PM_INTERNALS_DIR="$PM_ROOT_DIR/.internals"

## main wrapper function (with directory handling) -> user entry point
function pm() {
	local current_directory=$(PWD)
	cd $PM_ROOT_DIR
	pm::main "$@"
	cd $current_directory
	return 0
}

## raw colors and control characters
export TAB="\t";
export RGL="\e[0;0m";
export BLD="\e[0;1m";
export ITA="\e[0;3m";
export UL="\e[0;4m";
export HL="\e[0;7m";
export ST="\e[0;9m";
export GRY="\e[0;30m";
export RED="\e[0;31m";
export GRN="\e[0;32m";
export YLO="\e[0;33m";
export BLU="\e[0;34m";
export PRP="\e[0;35m";
export LBL="\e[0;36m";
## io -> control characters
function pm::io::tab() { printf "\t$@"; }
function pm::io::regular() { printf "\e[0;0m$@"; }
function pm::io::bold() { printf "\e[0;1m$@"; }
function pm::io::italic() { printf "\e[0;3m$@"; }
function pm::io::underline() { printf "\e[0;4m$@"; }
function pm::io::highlight() { printf "\e[0;7m$@"; }
function pm::io::strikethrough() { printf "\e[0;9m$@"; }
## io -> colors
function pm::io::grey() { printf "\e[0;30m$@"; }
function pm::io::gray() { printf "\e[0;30m$@"; }
function pm::io::red() { printf "\e[0;31m$@"; }
function pm::io::green() { printf "\e[0;32m$@"; }
function pm::io::yellow() { printf "\e[0;33m$@"; }
function pm::io::blue() { printf "\e[0;34m$@"; }
function pm::io::purple() { printf "\e[0;35m$@"; }
function pm::io::lightblue() { printf "\e[0;36m$@"; }
## io -> other
function pm::io::pretty() {
	case $# in
		0) local strings="$(< /dev/stdin)";;
		1) local strings="$1";;
		*) local strings="$@";;
	esac
	pm::io::bold ; echo "$strings" ; pm::io::regular ;
	#elif [ $# -gt 1 ]; then
	#	for i in $@; do
	#		pm::io::bold ; echo $i ; pm::io::regular ;
	#	done
	#else
}
function pm::io::usage() {
	## if the first argument is blank, set the usage text to pm's usage, 
	## otherwise print the usage text supplied
	if [ ! "$1" ]; then
		local usage=$PM_USAGE_PRETTY
	else
		local usage="$1"
	fi
	case "$2" in
		full|key)usage+=$PM_USAGE_PRETTY_KEY;;
	esac
	printf "$usage\n" || return 1
}
## a bit like pm::manifest, but just top-level package directory names, and not json
function pm::package::list() {
	pm::io::green "$(ls -d $PM_DISTRIBUTIONS_DIR/* | sed 's/.*\///')\n"
}

## prettifies the manifests;
## same as calling pm::manifest::json | jq
function pm::manifest::pretty() {
					if which jq &>/dev/null; then
						pm::manifest::json | jq "$@" || return 1
					else
						pm::manifest::json || return 1
					fi
}

## list (as json) valid directories (directories which contain a 
## .manifest or module.sh which we can interact with)
function pm::scan() { pm::manifest::json; }
function pm::scan::json() { pm::manifest::json; }
function pm::manifest() { pm::manifest::json; }
function pm::manifest::json() {
	local search="{";
	for i in $(ls); do
		if [ -L $i ] && [ -f $i/module.sh ]; then
			cd $i;
			search+="\"${PWD##*/}\":\"$(readlink ../$i)\",";
			cd ..;
		elif [ -d $i ] && [ -f $i/.reference ]; then
			for reference in $(ls -F $i | grep -v /); do
				search+="\"${$(basename $reference)%%.*}\": \"${reference##*.}\","
			done
		elif [ -d $i ] && [ -f $i/.note ]; then
			cd $i
			search+="\"${PWD##*/}\":$(pm::manifest::json),";
			cd ..
		elif [ -f .note ]; then
			for note in $(ls -F | grep -v /); do
				search+="\"${$(basename $note)%%.*}\": \"${note##*.}\","
			done
		elif [ -d $i ] && [ -f $i/module.sh ]; then
			cd $i;
			search+="\"${PWD##*/}\":\"module\",";
			cd ..;
		elif [ -f $i/.manifest ]; then
			cd $i;
			search+="\"${PWD##*/}\":$(pm::manifest::json),";
			cd ..;
		fi;
	done;
	search+="}";echo $search|sed "s/,}/}/";
}

function pm::call::constitution() {
	source $PM_CONSTITUTION_LOC
}

function pm::call::module() {
	## need to check this; sending empty strings as arguments works.
	## checking if an empty string is "not" there... also works.
	echo $@
	echo $1
	echo $2
	if [ ! "$1" ]; then pm::io::red "fatal: improper command usage\n"; return 1; fi
	case $# in
		2)
			local package_name="$1"
			local version="default"
			local arguments="$2"
		;;
		3)
			local package_name="$1"
			local version="$2"
			local arguments="$3"
		;;
		4)
			local package_name="$1"
			local version="$2"
			local arguments="$3 $4"
		;;
		*)
			pm::io::red "fatal: improper command usage\n"
			pm::io::usage
			return 1
		;;
	esac
	local last_dir="$PWD"
	if ! cd "$PM_DISTRIBUTIONS_DIR/$package_name/$version" ; then
		pm::io::red "fatal: package not found or not viable\n"
		cd $last_dir
		return 1
	else
		./module.sh "$arguments"
	fi
	cd $last_dir
	return 0
	#if [ -d "$PM_DISTRIBUTIONS_DIR/$package_name/$version" ]; then
	#	cd "$PM_DISTRIBUTIONS_DIR/$package_name/$version"
	#	./module.sh "$arguments"
	#else
	#	pm::io::red "fatal: package not found or not viable\n"
	#fi
}

function pm::seq() {
	case $# in
		1)
			local first=0
			local step=1
			local last=$1
		;;
		2)
			local first=$1
			local step=1
			local last=$2
		;;
		3)
			local first=$1
			local step=$2
			local last=$3
		;;
		*)
			return 1
		;;
	esac
	seq -s, $first $step $last | sed 's/,$//'
	return 0
}

function pm::methods() {
	methods="{\"methods\":["
	for i in ${PM_METHODS[@]}; do
		methods+="\"$i\","
	done
	methods+="]}"
	case $1 in
		pretty)echo $methods | sed 's/,]/]/g'|jq;;
		*)echo $methods | sed 's/,]/]/g';;
	esac
	return 0
}

# usage -> install <package name> [version]
function pm::package::install() {
		if [[ $# -eq 0 ]]; then pm::io::usage; return 1; fi
		local last_directory=$(pwd)
		local package_name="$1"
		if [[ $# -eq 2 ]]; then
				local version="$2"
		else
				local version="default"
		fi
	# go to the package's directory
		local package_directory="$PM_DISTRIBUTIONS_DIR/$package_name/$version"
		if [[ ! -f "$package_directory/module.sh" ]]; then
				pm::io::pretty "package not found"
				return 1
		else
	# install it
				pm::io::pretty "installing package $package_name/$version"
				cd "$package_directory"
				./module.sh install
		fi
		cd $last_directory
		pm::io::pretty "done"
		return 0
}

function pm::package::create() {
 if [[ $# -ne 2 ]]; then
	pm::io::usage
	return 1
 else
	local package_name="$1"
	if [[ $2 = "" ]]; then
	 local version="1.0.0"
	else
	 local version="$2"
	fi
	pm::io::pretty "creating package $package_name/$version"
	local last_dir=$(pwd)
	cd "$PM_DISTRIBUTIONS_DIR"
	if [[ -d "$package_name/$version" ]]; then
		echo "cannot overwrite package $package_name/$version"
		return 1
	fi
	mkdir -p "$package_name/$version/package-generic"
	cp "gcc/.manifest" "$package_name/"
	cd "$package_name"
	ln -s "$version" latest
	ln -s "$version" default
	touch "$version/module.sh"
	chmod +x "$version/module.sh"
	mkdir "$version/package-generic"
	cd $last_dir
 fi
 pm::io::pretty "done"
 return 0
}

## main argument parsing
function pm::parse_arguments() {
	case "$1" in
			## pm list -> list available packages
		list)
			pm::package::list || return 1
		;;## pm install -> install a given package
		install|add)
			local _begin_arg=2
			local subargs=""
			if [ $# -gt 3 ]; then
				## make a string of all arguments from 2 to n
				for (( i = $_begin_arg; i <= $#; i++ )); do
					if [ $i -eq 3 ]; then
						subargs+="default "
					elif [ $i -eq 4 ]; then
						subargs+="install "
					else
						subargs+="${@[$i]} "
					fi
				done
			else
				subargs="$2 default install"
			fi
			## and pass it to the function
			pm::call::module "$subargs" || return 0
			
			#pm::call::module "$2" "default" "install" || return 1
			#pm::package::install "$2" || return 1
		
		;;## pm create -> create a boilerplate package
		create)
			pm::package::create "$2" "$3" || return 1
		;;## pm scan -> list all current functionality
		scan|manifest)
			case "$2" in
				raw) pm::manifest::json || return 1;;
				*) pm::manifest::pretty "$3" || return 1;;
			esac
		;;## pm module <name> -> pass arguments along to the given module
		module)
			## make a string of all arguments from 2 to n
			local _begin_arg=2
			local subargs=""
			for (( i = $_begin_arg; i <= $#; i++ )); do
				subargs+="${@[$i]} "
			done
			echo "$subargs"
			pm::call::module "$subargs" || return 1	
			#pm::call::module "$2" "$3" || return 1
		
		;;## pm query|info <module name> -> describe a module
		query|info)
			case "$2" in
				note) 
					if [ "$3" = "" ] || [ ! -f "$PM_ROOT_DIR/notes/$3" ]; then
						pm::io::usage "$PM_USAGE_PRETTY" "full"
					else
						cat "$PM_ROOT_DIR/notes/$3"
					fi
					;;
				ref|reference)
					if [ "$3" = "" ] || [ ! -f "$PM_ROOT_DIR/reference/$3" ]; then
						pm::io::usage "$PM_USAGE_PRETTY" "full"
					else
						cat "$PM_ROOT_DIR/reference/$3"
					fi
					;;
				*) pm::call::module "$2" "describe" || return 1;;
			esac
		;;##pm methods -> list internal methods
		methods)
			pm::methods "$2" || return 1
		;;## pm help -> describe ourselves
		usage|help)
			case "$2" in
				raw) pm::io::usage "$PM_USAGE" "$3" || return 1;;
				full) pm::io::usage "$PM_USAGE_PRETTY" "full" || return 1;;
				*) pm::io::usage "$PM_USAGE_PRETTY" "$3" || return 1;;
			esac
		;;## default -> print usage
		*)
			pm::io::usage "$PM_USAGE_PRETTY"
			return 1
		;;
	esac
}

function module::io::usage() { pm::io::usage; }
## describe a module's properties;
## invalid if it does not implement
## at least what is specified in the constitution
function module::io::describe() {
	case $1 in
		raw)
			echo $json_description
		;;
		*)
			if which jq &> /dev/null; then
				echo $json_description
			else
				echo $json_description
			fi
		;;
	esac
}
function module::host::viable() {
  if [ $initialized = "true" ]; then
    if [ $package_is_viable = "false" ]; then
      pm::io::pretty "fatal: no viable packages for $host_architecture"
      return 1
    else
      return 0
    fi
  else
    return 1
  fi
}
## module argument parsing
function module::parse_arguments() {
	# <module name (implicit)> 
	# <[help|usage]|[install|add]|describe|run>
  case $@ in
  	help|usage);;
  	install|add);;
  	describe|description|desc);;
  	run);;

    desc*)
      module::cli::describe
    ;;
    install|add)
			if module::host::viable; then
      	module::install
			else
				pm::io::pretty "fatal: no viable packages for $host_architecture"
			return 1
			fi
    ;;
    usage|help)
      module::cli::usage
    ;;
    *)
      module::cli::usage
      return 1
    ;;
  esac
}

## pm main
function pm::main() {
	#pm::call::constitution
	source "$PM_CONSTITUTION_LOC"
	pm::parse_arguments "$@"
}

## module main
function module::main() {
	source "$PM_CONSTITUTION_LOC"
	module::parse_arguments "$@"
}

## usage keys (pm help)
PM_USAGE="
usage|help [raw|pretty[full|key]]
install|add <package name> [version]
query|info <module name> [version]
module <module name> <[help|usage]|[install|add]|describe|run>
methods [raw|pretty]
create <name> <version>
manifest|scan
list
"
PM_USAGE_PRETTY="
"$GRN"pm"$YLO"("$PRP"usage"$YLO"\
|"$PRP"help"$YLO"["$ITA"raw"$YLO"|"$ITA"pretty"$YLO"\
["$ITA"full"$YLO"|"$ITA"key"$YLO"]=>"$BLU"pretty"$YLO"])
"$GRN"pm"$YLO"("$PRP"install"$YLO"\
|"$PRP"add"$YLO"("$ITA"package"$YLO"("$ITA"version"$YLO"=>"$BLU"latest"$YLO")))
"$GRN"pm"$YLO"("$PRP"query"$YLO"\
|"$PRP"info"$YLO"("$ITA"module"$YLO"("$ITA"version"$YLO"=>"$BLU"latest"$YLO")))
"$GRN"pm"$YLO"("$PRP"module"$YLO"\
("$ITA"module"$YLO","$YLO"(["$ITA"help"$YLO"|"$ITA"usage"$YLO"]|\
["$ITA"install"$YLO"|"$ITA"install"$YLO"]|"$ITA"describe"$YLO"|"$ITA"run"$YLO")))
"$GRN"pm"$YLO"("$PRP"methods"$YLO"\
["$ITA"raw"$YLO"|"$ITA"pretty"$YLO"=>"$BLU"pretty"$YLO"])
"$GRN"pm"$YLO"("$PRP"create"$YLO"\
("$ITA"name"$YLO","$ITA"version"$YLO")
"$GRN"pm"$YLO"("$PRP"manifest"$YLO"\
|"$PRP"scan"$YLO")
"$GRN"pm"$YLO"("$PRP"list"$YLO")
"
PM_USAGE_PRETTY_KEY="
"$PRP"method
"$ITA"one"$YLO"|"$ITA"of"$YLO"
"$ITA"all"$YLO","$ITA"of"$YLO"
"$GRN"command
"$ITA"argument
"$YLO"=>"$BLU"default
"$YLO"("$ITA"required"$YLO")
"$YLO"["$ITA"optional"$YLO"]
"$YLO"annotation
"

PM_DEFINITIONS=(									\
"PM_ROOT_DIR"											\
"PM_CONSTITUTION_LOC"							\
"PM_DISTRIBUTIONS_DIR"						\
"PM_CONFIGURATIONS_DIR"						\
"PM_SOURCES_DIR"									\
"PM_BUILDS_DIR"										\
"PM_STORES_DIR"										\
"PM_INTERNALS_DIR"								\
"PM_USAGE"												\
"PM_USAGE_PRETTY"									\
"PM_USAGE_PRETTY_KEY"							\
)

PM_METHODS=(											\
"pm" 															\
"pm::main"												\
"pm::seq" 												\
"pm::methods" 										\
"pm::scan" 												\
"pm::scan::json" 									\
"pm::manifest"									 	\
"pm::manifest::json" 							\
"pm::call::constitution" 					\
"pm::call::module" 								\
"pm::io::tab" 										\
"pm::io::regular" 								\
"pm::io::bold"									 	\
"pm::io::italic" 									\
"pm::io::underline" 							\
"pm::io::highlight" 							\
"pm::io::strikethrough" 					\
"pm::io::grey" 										\
"pm::io::gray" 										\
"pm::io::red" 										\
"pm::io::green" 									\
"pm::io::yellow" 									\
"pm::io::blue" 										\
"pm::io::purple" 									\
"pm::io::lightblue" 							\
"pm::io::pretty" 									\
"pm::io::usage" 									\
"pm::package::create" 						\
"pm::parse_arguments" 						\
)
#"pm::package::install" 					\

PM_MODULE_METHODS=(								\
"module::parse_arguments"					\
"module::cli::install"						\
"module::cli::run"								\
"module::cli::describe"						\
"module::cli::usage"							\
"module::state::initialized"			\
"module::host::installed"					\
"module::host::viable"						\
"module::host::architecture"			\
"module::package::architecture"		\
"module::package::version"				\
"module::package::type"						\
"module::package::name"						\
"module::package::path"						\
"module::description"							\
"module::version"									\
"module::name"										\
"module::main"										\
)

## exports
for i in $PM_DEFINITIONS; do
	export $i
done
for i in $PM_METHODS; do
	export -f $i &>/dev/null
done
for i in $PM_MODULE_METHODS; do
	export -f $i &>/dev/null
done
