#pragma semicolon 1

#include sourcemod
#include sdktools
#file "StringTable Dumper"

public Plugin myinfo = {
	name = "StringTable Dumper",
	description = "Recreaction of dumpstringtables command",
	author = "MAGNAT2645",
	version = "0.1",
	url = ""
};

public void OnPluginStart() {
	RegServerCmd( "sm_stringtables", SCMD_StringTables, "Dump stringtables to file" );
}

public Action SCMD_StringTables(int args) {
	File hFile = OpenFile( "stringtables.txt", "w" );
	int iLength = GetNumStringTables(), iSize;
	char sName[ PLATFORM_MAX_PATH ];

	for ( int i = 0; i < iLength; i++ ) {
		iSize = GetStringTableNumStrings( i );
		GetStringTableName( i, sName, sizeof( sName ) );
		hFile.WriteLine( "Table %s\n  %i/%i items", sName, iSize, GetStringTableMaxStrings( i ) );
		for ( int x = 0; x < iSize; x++ ) {
			ReadStringTable( i, x, sName, sizeof( sName ) );
			hFile.WriteLine( "%i : %s", x, sName );
		}
		hFile.WriteLine( "" ); // newline
	}

	hFile.Close();
	PrintToServer( "Dump written to stringtables.txt" );

	return Plugin_Handled;
}