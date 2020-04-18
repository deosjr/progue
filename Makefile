.PHONY: run, test

run: 
	swipl -l progue.pl -t start_game

test:
	swipl -l progue.pl -t run_tests
