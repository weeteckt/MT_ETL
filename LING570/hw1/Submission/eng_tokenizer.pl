#!/usr/bin/perl

#-------------------------------------------------------------------------------------------
#
#  Main - Start.
#
#-------------------------------------------------------------------------------------------



$input_sentence ="";	


while($input_sentence = <STDIN>) {	## accept input from file
        clean_up_file ();
	output_text ();

}



#-------------------------------------------------------------------------------------------
#
#  Main - End.
#
#-------------------------------------------------------------------------------------------




sub clean_up_file {

	$formatted_sentence ="";

	if ($input_sentence ne " "){ 
		

		@token = split / /, $input_sentence;
	
		foreach $token(@token) {

				$token =~ s/\(/ \ ( /g;
				$token =~ s/\)/ \ ) /g;
				$token =~ s/\{/ \ { /g;
				$token =~ s/\}/ \ } /g;
				$token =~ s/\</ \ < /g;
				$token =~ s/\>/ \ > /g;
				$token =~ s/\[/ \ [ /g;
				$token =~ s/\]/ \ ] /g;
				$token =~ s/\-/ \ - /g;
				$token =~ s/\\/ \ \ /g;
				$token =~ s/\"/ \ " /g;
				$token =~ s/\;/ \ ; /g;
				$token =~ s/\`/ \ ` /g;
				
				$token =~ s/\s+/ /g;
			

			if ($token =~ /\$[0-9]/) {	
			
				$token =~ s/\$/\$ /g;
			}


			elsif (!($token =~ /[A-Z]\./) && !($token =~ /[0-9]\:[0-9]/) && !($token =~ /[0-9]\.[0-9]/) && !($token =~ /[0-9]\,[0-9]/) && !($token =~ /[0-9]\/[0-9]/)) {

				$token =~ s/\./ \. /g;
				$token =~ s/\?/ \? /g;
				$token =~ s/\!/ \! /g;
				$token =~ s/\,/ \, /g;
				$token =~ s/\:/ \: /g;
				$token =~ s/\// \/ /g;

				$token =~ s/\s+/ /g;	
			}
				
			
			if (($token =~ /n't/)||($token =~ /'d/)||($token =~ /'ll/)||($token =~ /I'm/)||($token =~ /'re/)||($token =~ /'ve/)||($token =~ /'s/)||($token =~ /s'/)||($token =~ /[A-Za-z0-9]'[A-Za-z0-9]/)) {

				$token =~ s/n't/ n't/g;
				$token =~ s/'s/ 's/g;
				$token =~ s/'S/ 'S/g;
				$token =~ s/'d/ 'd/g;
				$token =~ s/'ll/ 'll/g;
				$token =~ s/I'm/I 'm/g;
				$token =~ s/'re/ 're/g;
				$token =~ s/'ve/ 've/g;
				$token =~ s/s'/s '/g;
				$token =~ s/S'/S '/g;
			}

			else {

				$token =~ s/'/ '/g;

			}


			if (($token =~ /\.\,/) || ($token =~ /\.\;/) || ($token =~ /\.\./) || ($token =~ /\,\./)) {

				$token =~ s/\.\,/\. \,/g;
				$token =~ s/\.\./\. \./g;
				$token =~ s/\,\./\, \./g;				
			}


			if (($token =~ /[0-9]\,[0-9]/) || ($token =~ /[0-9]\.[0-9]/)) {

				$token = $token . " ";
				$token =~ s/\. / \./g;
				$token =~ s/\, / \,/g;
				$token =~ s/\: / \:/g;

				$token =~ s/\! / \!/g;
				$token =~ s/\? / \?/g;
			}
			


			if ($token =~ /[0-9]\/[0-9]/) {

				$token =~ s/\./ \./g;
				$token =~ s/\,/ \,/g;
				$token =~ s/\:/ \:/g;

				$token =~ s/\!/ \!/g;
				$token =~ s/\?/ \?/g;
			}	


		$token =~ s/^\s+//g;
		$token =~ s/\s+$//g;
		$formatted_sentence = $formatted_sentence . $token . " ";


		}
	}	
}




sub output_text {

	if ($formatted_sentence eq " ") {
		
		print "\n"
	}
	

	else {
			
		print " " ,$formatted_sentence, "\n";
	}	
}