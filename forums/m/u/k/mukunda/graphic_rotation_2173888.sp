#include <sourcemod> 

// 1.1
//   csgo update, multiple graphic slots
   
//-------------------------------------------------------------------------------------------------
public Plugin:myinfo =
{
	name = "Server Graphic Rotation",
	author = "mukunda",
	description = "Change sv_server_graphics each map",
	version = "1.1.0",
	url = "www.mukunda.com"
};

new Handle:g_graphic_lists[2] = {INVALID_HANDLE,...}; // data packs for each graphic list

//-------------------------------------------------------------------------------------------------
public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	// check that config exists, and don't load if it's missing
	decl String:configpath[256];
	BuildPath( Path_SM, configpath, sizeof(configpath), "configs/server_graphics.cfg" );
	if( !FileExists( configpath ) ) {
		LogMessage( "server_graphics.cfg is missing." );
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

//-------------------------------------------------------------------------------------------------
public OnPluginStart() {
	// load config
	
	decl String:configpath[256];
	BuildPath( Path_SM, configpath, sizeof(configpath), "configs/server_graphics.cfg" );
	
	new Handle:kv = CreateKeyValues( "ServerGraphics" );
	if( !FileToKeyValues( kv, configpath ) ) {
		CloseHandle( kv );
		SetFailState( "Error loading config file \"%s\"", configpath );
	} 
	
	LoadGraphicList( kv, "Graphic1", g_graphic_lists[0] );
	LoadGraphicList( kv, "Graphic2", g_graphic_lists[1] );
	
	CloseHandle( kv );
	
	ChangeGraphic(); // set initial graphic
}

//-------------------------------------------------------------------------------------------------
LoadGraphicList( Handle:kv, const String:name[], &Handle:pack ) {
	if( !KvJumpToKey( kv, name ) ) return; // graphic list not present
	if( !KvGotoFirstSubKey( kv, false ) ) {
		KvGoBack( kv );
		return; // graphic list is empty
	}
	
	pack = CreateDataPack();
	
	do {
		decl String:graphic[64];
		KvGetString( kv, "", graphic, sizeof graphic );
		WritePackString( pack, graphic );
	} while( KvGotoNextKey( kv, false ) );
	
	ResetPack(pack);
	
	KvGoBack(kv);
	KvGoBack(kv);
}

//-------------------------------------------------------------------------------------------------
ChangeGraphic() {
	// read graphic entry and increment
	
	for( new index = 0; index < 2; index++ ) {
		
		if( g_graphic_lists[index] == INVALID_HANDLE ) continue;
		
		decl String:graphic[64];
		if( !IsPackReadable( g_graphic_lists[index], 1 ) ) {
			ResetPack( g_graphic_lists[index] );
		}
		
		ReadPackString( g_graphic_lists[index], graphic, sizeof graphic );
		
		decl String:cvarname[64];
		FormatEx( cvarname, sizeof cvarname, "sv_server_graphic%d", index+1 );
		SetConVarString( FindConVar( cvarname ), graphic );
		PrintToServer( "Set server graphic %d to \"%s\".", index+1, graphic );
	}
}
 
//-------------------------------------------------------------------------------------------------
public OnMapEnd() {
	// change before map load
	ChangeGraphic();
	
}
