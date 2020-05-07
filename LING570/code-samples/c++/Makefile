PROGRAM=ncat

$(PROGRAM): $(PROGRAM).o
	c++ -W3 -Werror -o $@ $<
 
$(PROGRAM).o: $(PROGRAM).cpp
	c++ -c -o $@ $<
 
.PHONY: clean
 
clean:
	rm -f $(PROGRAM) $(PROGRAM).o
