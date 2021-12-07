#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <geoip>

#define CVAR_FLAGS FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
#define VERSION "2.5.0"
#define MAX_NAME_LENGTH_NON_OFFICIAL 50

new UserMsg:g_SayText2;
new String:OriginalName[20][MAX_NAME_LENGTH_NON_OFFICIAL];

new Handle:PlayerJoinMessage = INVALID_HANDLE;
new Handle:PlayerJoinMessageLayout = INVALID_HANDLE;
new Handle:ShowIsAdminOnMessages = INVALID_HANDLE;
new Handle:ShowIsAdminInScore = INVALID_HANDLE;
new Handle:NameLayout = INVALID_HANDLE;
new Handle:AdminLayout = INVALID_HANDLE;
new Handle:PACTLIST_Layout = INVALID_HANDLE;
new Handle:PluginVersionCVAR = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "PlayerAddCountryTag",
	author = "n3wton",
	description = "Add country tag to users name",
	version = VERSION
};

public OnPluginStart()
{

	PlayerJoinMessage = CreateConVar("PACT_Player_Join_Message", "1", "Show a message on player join ('PLAYER' from 'LOCATION' has joined)", CVAR_FLAGS);
	PlayerJoinMessageLayout = CreateConVar("PACT_Player_Join_Message_Layout", "{NAME} from {LOC} has joined.", "Format of the welcome message, {NAME} = player name, {LOC} = country", CVAR_FLAGS);
	ShowIsAdminOnMessages = CreateConVar("PACT_Show_Admin_Messages", "1", "Highlight admins in yellow in chat messages", CVAR_FLAGS);
	ShowIsAdminInScore = CreateConVar("PACT_Show_Admin_Score", "1", "Put AdminTag infront of all admins in score", CVAR_FLAGS);
	NameLayout = CreateConVar("PACT_Name_Layout", "{NAME} [{TAG}]", "Layout of how the clients name should look", CVAR_FLAGS);
	AdminLayout = CreateConVar("PACT_Admin_Layout", "(A) {NAME}", "Layout of how and what the admin tag should look like, (Note: {NAME} equates to the string genorated from PACT_Name_Layout", CVAR_FLAGS );
	PACTLIST_Layout = CreateConVar("PACT_List_Layout", "{NAME} is from {LOC}", "Layout of how !pactlist should be displayed", CVAR_FLAGS);
	PluginVersionCVAR = CreateConVar("PACT_Version", VERSION, "Version of the Player Add Country Tag (PACT) plugin.", CVAR_FLAGS);
	AutoExecConfig(true, "PlayerAddCountryTag");
	
	g_SayText2 = GetUserMessageId("SayText2");
	HookUserMessage(g_SayText2, UserMessageHook, true);
	HookEvent("player_changename", Event_PlayerChangename, EventHookMode_Pre);
	
	RegConsoleCmd("sm_pactlist", listPlayersAndCountry, "List all players names and countries");
}

public OnClientPostAdminCheck(client)
{
	if( client != 0 )
	{
		if( !IsFakeClient( client ) )
		{
			new String:IP[16];
			new String:Country[100];
			
			GetClientIP( client, IP, 16 );
			
			if( GetConVarBool(PlayerJoinMessage) )
			{
				if( GeoipCountry( IP, Country, 100 ) )
				{
					new String:JoinMessage[256];
					new String:Name[MAX_NAME_LENGTH_NON_OFFICIAL];
					GetClientName( client, Name, MAX_NAME_LENGTH_NON_OFFICIAL );
					
					if( StrContains( Country, "United", false ) != -1 || StrContains( Country, "Republic", false ) != -1 || StrContains( Country, "Netherlands", false ) != -1 || StrContains( Country, "Philippines", false ) != -1 )
					{
						Format( Country, 100, "The %s", Country );
					}
					
					GetConVarString(PlayerJoinMessageLayout, JoinMessage, 256);
					if (StrContains(JoinMessage, "{NAME}", false) != -1) ReplaceString(JoinMessage, sizeof(JoinMessage), "{NAME}", Name);
					if (StrContains(JoinMessage, "{LOC}", false) != -1) ReplaceString(JoinMessage, sizeof(JoinMessage), "{LOC}", Country);
					
					if( GetUserAdmin(client) != INVALID_ADMIN_ID && GetConVarBool(ShowIsAdminOnMessages) )
					{
						PrintToChatAll("\x04%s", JoinMessage);
					}
					else
					{
						PrintToChatAll(JoinMessage);
					}
				}
				else
				{
					if( GetUserAdmin(client) != INVALID_ADMIN_ID && GetConVarBool(ShowIsAdminOnMessages) )
					{
						PrintToChatAll( "\x04%N has joined", client );
					}
					else
					{
						PrintToChatAll( "%N has joined", client );
					}
				}
			}
			
			GetClientName( client, OriginalName[client], MAX_NAME_LENGTH_NON_OFFICIAL );

			new String:NameWithTag[MAX_NAME_LENGTH_NON_OFFICIAL];
			getPlayerNameWithTag( client, NameWithTag, MAX_NAME_LENGTH_NON_OFFICIAL );
			SetClientInfo( client, "name", NameWithTag );
			
			//If Admin and Config Wrong Show Error Message
			if( GetUserAdmin( client ) != INVALID_ADMIN_ID && GetConVarFloat(PluginVersionCVAR) != StringToFloat(VERSION) ) 
			{
				PrintToChat( client, "\x03PACT ERROR!" );
				PrintToChat( client, "\x03You are using plugin version %s", VERSION );
				PrintToChat( client, "\x03Where as your .cfg is using version %f.", GetConVarFloat(PluginVersionCVAR) );
				PrintToChat( client, "\x03Please delete your .cfg file from cfg/sourcemod and restart the server" );
			}
		}
	}
}

public Action:listPlayersAndCountry(client, args)
{
	if( client != 0 )
	{
		if( !IsFakeClient( client ) )
		{
			for( new i = 1; i<=MaxClients; i++)
			{
				if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
				{
					new String:Country[100];
					new String:IP[16];
					new String:Layout[256];
					GetConVarString( PACTLIST_Layout, Layout, 256 );
					GetClientIP(i, IP, 16);
					if( !GeoipCountry(IP, Country, 100) )
					{
						Format( Country, 100, "an Unknown Location" );
					}
					if( StrContains( Country, "United", false ) != -1 || StrContains( Country, "Republic", false ) != -1 || StrContains( Country, "Netherlands", false ) != -1 || StrContains( Country, "Philippines", false ) != -1 )
					{
						Format( Country, 100, "The %s", Country );
					}
					if( StrContains( Layout, "{NAME}", false ) != -1 )
					{
						ReplaceString( Layout, 256, "{NAME}", OriginalName[i], false );
					}
					if( StrContains( Layout, "{LOC}", false ) != -1 )
					{
						ReplaceString( Layout, 256, "{LOC}", Country, false );
					}
					if( GetUserAdmin(i) != INVALID_ADMIN_ID && GetConVarBool(ShowIsAdminOnMessages) )
					{	
						PrintToChat( client, "\x04%s", Layout );
					}
					else
					{
						PrintToChat( client, "%s", Layout );		
					}
				}
			}
		}
	}
}

getPlayerTag(client, String:Tag[], size)
{
	new String:IP[16];
	new String:Code[3];
	Format( Tag, size, "%s", "--" ); 
	GetClientIP(client, IP, 16);
	if( GeoipCode2(IP, Code) )
	{
		Format( Tag, size, "%2s", Code ); 
	}
}

getPlayerNameWithTag(client, String:NameWithTag[], size)
{
	new String:Tag[5];
	new String:Name[MAX_NAME_LENGTH_NON_OFFICIAL];
	new String:Layout[256];
	
	GetClientName( client, Name, MAX_NAME_LENGTH_NON_OFFICIAL );
	getPlayerTag( client, Tag, 5 );
	
	GetConVarString( NameLayout, Layout, 256 );
	if( StrContains( Layout, "{NAME}", false ) != -1 )
	{
		ReplaceString(Layout, sizeof(Layout), "{NAME}", Name);
	}	
	if( StrContains( Layout, "{TAG}", false ) != -1 )
	{
		ReplaceString(Layout, sizeof(Layout), "{TAG}", Tag);
	}
	Format( NameWithTag, size, "%s", Layout );	
	if( GetUserAdmin( client ) != INVALID_ADMIN_ID && GetConVarBool(ShowIsAdminInScore) )
	{ //if they are an admin
		new String: AdmLayout[256];
		GetConVarString( AdminLayout, AdmLayout, 256 );
		if( StrContains( AdmLayout, "{NAME}", false ) != -1 )
		{
			ReplaceString( AdmLayout, sizeof(AdmLayout), "{NAME}", NameWithTag );
		}
		Format(  NameWithTag, size, "%s", AdmLayout );
	}
}

public Action:UserMessageHook(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
    decl String:message[256];
    BfReadString(bf, message, sizeof(message));
    BfReadString(bf, message, sizeof(message));
    if (StrContains( message, "Name_Change", false) != -1)
	{
		return Plugin_Handled;
	}
    return Plugin_Continue;
}  

public Action:Event_PlayerChangename(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId( GetEventInt(event, "userid") );
	
	if( client != 0 )
	{
		if( !IsFakeClient( client ) )
		{
			new String:NewName[MAX_NAME_LENGTH_NON_OFFICIAL];
			new String:Tag[5];
			new String:Layout[256];
			
			GetEventString( event, "newname", NewName, MAX_NAME_LENGTH_NON_OFFICIAL );
			getPlayerTag( client, Tag, 5 );
			
			if( StrContains( NewName, Tag, false ) == -1 )
			{				
				GetConVarString( NameLayout, Layout, 256 );
				if( StrContains( Layout, "{NAME}", false ) != -1 )
				{
					ReplaceString(Layout, sizeof(Layout), "{NAME}", NewName);
				}	
				if( StrContains( Layout, "{TAG}", false ) != -1 )
				{
					ReplaceString(Layout, sizeof(Layout), "{TAG}", Tag);
				}
				Format( NewName, MAX_NAME_LENGTH_NON_OFFICIAL, "%s", Layout);
			}
			
			if( GetUserAdmin( client ) != INVALID_ADMIN_ID )
			{
				new String: AdmLayout[256];
				GetConVarString( AdminLayout, AdmLayout, 256 );
				ReplaceString( AdmLayout, 256, "{NAME}", "" );
				if( StrContains( NewName, AdmLayout, false ) == -1 )
				{				
					GetConVarString( AdminLayout, AdmLayout, 256 );
					if( StrContains( AdmLayout, "{NAME}", false ) != -1 )
					{
						ReplaceString( AdmLayout, sizeof(AdmLayout), "{NAME}", NewName );
					}
					Format(  NewName, MAX_NAME_LENGTH_NON_OFFICIAL, "%s", AdmLayout );
				}
			}
			
			SetClientInfo( client, "name", NewName );
			
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}