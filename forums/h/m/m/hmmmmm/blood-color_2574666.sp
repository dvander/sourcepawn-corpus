#include <sourcemod>
#include <cstrike>
#include <dhooks>

Handle g_hBloodColor;

ConVar g_cvCTColor;
ConVar g_cvTColor;

public Plugin myinfo = 
{
	name = "Blood Color Changer",
	author = "SlidyBat",
	description = "Changes blood colour of players depending on team",
	version = "0.1",
	url = "https://forums.alliedmods.net/showthread.php?t=304608"
};

public void OnPluginStart()
{
	g_cvCTColor = CreateConVar( "sm_ct_blood_color", "0", "Blood color of players on CT team.", _, true, -1.0, true, 4.0 ); // not sure if theres a maximum
	g_cvTColor = CreateConVar( "sm_t_blood_color", "0", "Blood color of players on T team.", _, true, -1.0, true, 4.0 );
	
	Handle temp = LoadGameConfigFile( "dhooks-test.games" );
	
	if( temp == INVALID_HANDLE )
	{
		SetFailState( "Why you no has gamedata?" );
	}
	
	int offset = GameConfGetOffset( temp, "BloodColor" );
	g_hBloodColor = DHookCreate( offset, HookType_Entity, ReturnType_Int, ThisPointer_CBaseEntity, BloodColorPost );
}

public void OnClientPutInServer( int client )
{
	DHookEntity( g_hBloodColor, true, client );
}

// int CBaseCombatCharacter::BloodColor(void)
public MRESReturn BloodColorPost( int pThis, Handle hReturn )
{
	//Change the bots blood color to goldish yellow
	if( GetClientTeam( pThis ) == CS_TEAM_CT )
	{
		DHookSetReturn( hReturn, g_cvCTColor.IntValue );
		return MRES_Supercede;
	}
	else if( GetClientTeam( pThis ) == CS_TEAM_T )
	{
		DHookSetReturn( hReturn, g_cvTColor.IntValue );
		return MRES_Supercede;
	}
	return MRES_Ignored;
}