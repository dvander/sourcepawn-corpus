#include <sourcemod>
#include <stringescape>


public OnPluginStart()
{
	// Just some strings to escape
	new String:firstString[] = "This is a normal string";
	new String:secondString[] = "Just use some ' chars, or more than one ' \'' '";
	new String:thirdString[] = "Just a \" \" escape it the \".. stupid \\\"\\\\\"";
	new String:fourthString[] = "We don't need the eeee, so escape them with a s";

	// Just Escape
	decl String:fourthOutput[sizeof(fourthString) * 2];

	// Output buffers mysql, twice size should be enough
	decl String:firstOutputMySQL[sizeof(firstString) * 2];
	decl String:secondOutputMySQL[sizeof(secondString) * 2];
	decl String:thirdOutputMySQL[sizeof(thirdString) * 2];

	// Output buffers sqlite, twice size should be enough
	decl String:firstOutputSQLite[sizeof(firstString) * 2];
	decl String:secondOutputSQLite[sizeof(secondString) * 2];
	decl String:thirdOutputSQLite[sizeof(thirdString) * 2];


	// Just Escape
	new escapedFourthChar = EscapeString(fourthString, 'e', 's', fourthOutput, sizeof(fourthOutput));


	// Now escape them :) First for mysql
	new escapedFirstCharMySQL = EscapeStringMySQL(firstString, firstOutputMySQL, sizeof(firstOutputMySQL));
	new escapedSecondCharMySQL = EscapeStringMySQL(secondString, secondOutputMySQL, sizeof(secondOutputMySQL), true);
	new escapedThirdCharMySQL = EscapeStringMySQL(thirdString, thirdOutputMySQL, sizeof(thirdOutputMySQL), false);

	// Now for sqlite
	new escapedFirstCharSQLite = EscapeStringSQLite(firstString, firstOutputSQLite, sizeof(firstOutputSQLite));
	new escapedSecondCharSQLite = EscapeStringSQLite(secondString, secondOutputSQLite, sizeof(secondOutputSQLite), true);
	new escapedThirdCharSQLite = EscapeStringSQLite(thirdString, thirdOutputSQLite, sizeof(thirdOutputSQLite), false);

	// Print result of first string
	PrintToServer("The first string '%s' is escaped for MySQL = '%s' (%i chars escaped) and for SQLite = '%s' (%i chars escaped)", 
			firstString, firstOutputMySQL, escapedFirstCharMySQL, firstOutputSQLite, escapedFirstCharSQLite);


	// Print result of second string
	PrintToServer("The second string '%s' is escaped for MySQL = '%s' (%i chars escaped) and for SQLite = '%s' (%i chars escaped)", 
			secondString, secondOutputMySQL, escapedSecondCharMySQL, secondOutputSQLite, escapedSecondCharSQLite);


	// Print result of third string
	PrintToServer("The third string '%s' is escaped for MySQL = '%s' (%i chars escaped) and for SQLite = '%s' (%i chars escaped)", 
			thirdString, thirdOutputMySQL, escapedThirdCharMySQL, thirdOutputSQLite, escapedThirdCharSQLite);

	// Print result of fourth string
	PrintToServer("The fourth string '%s' is escaped with 's' = '%s' (%i chars escaped)", 
			fourthString, fourthOutput, escapedFourthChar);

	/*
	Output:
	
	The first string 'This is a normal string' is escaped 
		for MySQL = 'This is a normal string' (0 chars escaped) and for SQLite = 'This is a normal string' (0 chars escaped)
	
	The second string 'Just use some ' chars, or more than one ' '' '' is escaped 
		for MySQL = 'Just use some \' chars, or more than one \' \'\' \'' (5 chars escaped) and for SQLite = 'Just use some '' chars, or more than one '' '''' ''' (5 chars escaped)
	
	The third string 'Just a " " escape it the ".. stupid \"\\"' is escaped 
		for MySQL = 'Just a \" \" escape it the \".. stupid \\\"\\\\\"' (8 chars escaped) and for SQLite = 'Just a "" "" escape it the "".. stupid \""\\""' (5 chars escaped)
	
	The fourth string 'We don't need the eeee, so escape them with a s' is escaped 
		with 's' = 'Wse don't nsesed thse sesesese, sso sesscapse thsem with a ss' (14 chars escaped)

	*/
}