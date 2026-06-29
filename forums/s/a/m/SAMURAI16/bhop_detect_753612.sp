#include <sourcemod>
#include <dukehacks>

public Plugin:myinfo = 
{
	name = "New SM Plugin",
	author = "SAMURAI",
	description = "",
	version = "0.1",
	url = ""
}

new g_iDetect[ MAXPLAYERS + 1] ;
new Float:g_pStrafe[ MAXPLAYERS + 1][ 3 ] ;

#define SUB_VECADJ 12
#define MAX_VECADJ 70

public OnPluginStart()
{
	dhAddClientHook(CHK_PreThink,fw_clientPrethink);
	
}

public Action:fw_clientPrethink( id )
{
	if( ! ( 1 <= id <= MaxClients ) )
		return ;
	
	if( !IsClientInGame( id ) && !IsPlayerAlive( id ) )
		return;
	
	decl Float:vAngles[3] ;
	decl iDetectClient    ;
	
	GetClientAbsAngles( id, vAngles ) ;
	
	iDetectClient = g_iDetect[ id ] ;
	
	if( vAngles[ 0 ] == g_pStrafe[ id ][ 0 ] && vAngles[1] == g_pStrafe[ id ][ 1 ] )
		iDetectClient -= SUB_VECADJ ;
	
	else 
		iDetectClient++;
		
	if( ( GetClientButtons( id ) & IN_JUMP ) && iDetectClient < 0 )
		iDetectClient = 0 ;
	
	if( iDetectClient > MAX_VECADJ && GetClientButtons( id ) & IN_JUMP )
	{
		// bhop detected 
		
		iDetectClient = 0 ;
	}
	
	g_iDetect[ id ] = iDetectClient ;
	
	UTIL_CopyVector( vAngles, g_pStrafe[ id ] )
	
}


stock UTIL_CopyVector(Float:fVec1[3], Float:fVec2[3])
{
	fVec2[0] = fVec1[0];
	fVec2[1] = fVec1[1];
	fVec2[2] = fVec1[2];
}
	
	