#pragma semicolon 1

#define PLUGIN_VERSION	"1.0.1"

public Plugin:myinfo =
{
	name = "Grenade type",
	author = "RedSword",
	description = "Add the type of grenade after the 'Fire in the hole!' message.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

enum TypeOfNade
{
	TN_NONE = 0,
	TN_HEGRE,
	TN_FLASH,
	TN_SMOKE
}

new TypeOfNade:g_iTypeNade[ MAXPLAYERS + 1 ];
new g_iNumberOfFITHToDo;

//GrenadeNames : CVar
new Handle:g_hHegreName;
new Handle:g_hFlashName;
new Handle:g_hSmokeName;

//GrenadeNames : Values
new String:g_szHegreName[ 32 ];
new String:g_szFlashName[ 32 ];
new String:g_szSmokeName[ 32 ];

public OnPluginStart()
{
	CreateConVar( "grenadetypeversion", PLUGIN_VERSION, "Gives plugin's version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD );
	
	g_hHegreName = CreateConVar( "grenadetype_hegrenadename", "HEGrenade", "Name of HEGrenades", 
		FCVAR_PLUGIN | FCVAR_NOTIFY );
	g_hFlashName = CreateConVar( "grenadetype_flashbangname", "Flashbang", "Name of flashbangs", 
		FCVAR_PLUGIN | FCVAR_NOTIFY );
	g_hSmokeName = CreateConVar( "grenadetype_smokename", "Smoke", "Name of smokes", 
		FCVAR_PLUGIN | FCVAR_NOTIFY );
	
	HookConVarChange( g_hHegreName, ConVarChange_HEGrenadeName );
	HookConVarChange( g_hFlashName, ConVarChange_FlashbangName );
	HookConVarChange( g_hSmokeName, ConVarChange_SmokeName );
	
	GetConVarString( g_hHegreName, g_szHegreName, sizeof(g_szHegreName) );
	GetConVarString( g_hFlashName, g_szFlashName, sizeof(g_szFlashName) );
	GetConVarString( g_hSmokeName, g_szSmokeName, sizeof(g_szSmokeName) );
	
	new UserMsg:umRadioText = GetUserMessageId("RadioText");
	if( umRadioText != INVALID_MESSAGE_ID )
		HookUserMessage(umRadioText, UserMsgRadioText, true);
	else
		SetFailState("GetUserMessageId of RadioText");
	
	LoadTranslations( "fireintheholegrenadetype.phrases" );
}

public OnClientDisconnect(iClient)
{
	if ( g_iTypeNade[ iClient ] )
	{
		g_iTypeNade[ iClient ] = TypeOfNade:TN_NONE;
		--g_iNumberOfFITHToDo;
	}
}

public OnGameFrame()
{
	if ( !g_iNumberOfFITHToDo )
		return;
	
	for ( new i = 1; g_iNumberOfFITHToDo != 0 && i <= MaxClients; ++i ) //MaxClients check for security; and to prevent impossible loop :3
	{
		if ( g_iTypeNade[ i ] == TN_NONE )
			continue;
		//Take for granted he's in game
		sendRadioTextToTeam( i, GetClientTeam( i ), g_iTypeNade[ i ] );
		
		//Remove the FITH to do
		g_iTypeNade[ i ] = TN_NONE;
		--g_iNumberOfFITHToDo;
	}
	g_iNumberOfFITHToDo = 0; //For safety :$ :/
}

public Action:UserMsgRadioText(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	decl String:radio_text[128];
	BfReadByte(bf); //=3
	new iClient = BfReadByte(bf);
	BfReadString(bf, radio_text, sizeof(radio_text));
	if(!strcmp(radio_text, "#Game_radio_location", false))
		BfReadString(bf, radio_text, 1); //no need to keep
	BfReadString(bf, radio_text, 1);
	
	BfReadString(bf, radio_text, sizeof(radio_text));

	if(StrEqual(radio_text, "#Cstrike_TitlesTXT_Fire_in_the_hole", false))
	{
		GetClientWeapon( iClient, radio_text, sizeof(radio_text) );
		
		//remove "weapon_"
		new bufferLen = strlen( radio_text );
		new i;
		for ( ; i < bufferLen - 7; ++i )
		{
			radio_text[ i ] = radio_text[ i + 7 ];
		}
		radio_text[ i ] = '\0';
		
		//Add a usermsg to launch on next frame
		if ( StrEqual( "hegrenade", radio_text ) )
		{
			g_iTypeNade[ iClient ] = TypeOfNade:TN_HEGRE;
		}
		else if ( StrEqual( "flashbang", radio_text ) )
		{
			g_iTypeNade[ iClient ] = TypeOfNade:TN_FLASH;
		}
		else /*if ( StrEqual( "smokegrenade", radio_text ) )*/ //Take for granted there is only that choice remaining
		{
			g_iTypeNade[ iClient ] = TypeOfNade:TN_SMOKE;
		}
		
		++g_iNumberOfFITHToDo;
		
		//sendRadioTextToTeam( iClient, GetClientTeam( iClient ), radio_text );
		
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

//===== HookConVarChange
public ConVarChange_HEGrenadeName(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy( g_szHegreName, sizeof(g_szHegreName), newValue );
}
public ConVarChange_FlashbangName(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy( g_szFlashName, sizeof(g_szFlashName), newValue );
}
public ConVarChange_SmokeName(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy( g_szSmokeName, sizeof(g_szSmokeName), newValue );
}

//--------------------------------------------------------------------------------------------------
//Following code mainly done by "javalia" (with some code changes)

//i dunno, what the hell is this magic number mean, i DUNNO!
#define RADIOTEXT_MAGIC_NUMBER 3

stock sendRadioTextToTeam(client, team, TypeOfNade:typeNade)
{
	if ( !IsClientInGame( client ) )
		return;
	
	decl String:sClientName[ MAX_NAME_LENGTH ];
	decl String:sPlaceName[ 128 ];
	decl String:msg[ 128 ];
	GetClientName( client, sClientName, MAX_NAME_LENGTH );
	GetEntPropString( client, Prop_Data, "m_szLastPlaceName", sPlaceName, sizeof(sPlaceName) );
	
	decl tmpTeam;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if ( IsClientInGame( i ) )
		{
			tmpTeam = GetClientTeam( i );
			if ( ( tmpTeam == team ) || ( tmpTeam == 1 ) )
			{
				decl String:nadeName[ 32 ];
				
				switch ( typeNade )//TODO CONTINUE
				{
				case TN_HEGRE :
					nadeName = g_szHegreName;
				case TN_FLASH :
					nadeName = g_szFlashName;
				case TN_SMOKE :
					nadeName = g_szSmokeName;
				default :
					nadeName[ 0 ] = '\0';
				}
				FormatEx( msg, sizeof(msg), "%T (%s)", "Fith4gt", i, nadeName );
				
				new Handle:buffer = StartMessageOne( "RadioText", i );
				
				if (buffer != INVALID_HANDLE)
				{
					BfWriteByte(buffer, RADIOTEXT_MAGIC_NUMBER);
					BfWriteByte(buffer, client);
					if ( StrEqual( sPlaceName, "", false ) )
						BfWriteString(buffer, "#Game_radio");
					else
						BfWriteString(buffer, "#Game_radio_location");
					
					BfWriteString(buffer, sClientName);
					
					if ( !StrEqual( sPlaceName, "", false ) )
						BfWriteString(buffer, sPlaceName);
					
					BfWriteString(buffer, msg);
					EndMessage(); 
				}
			}
		}
	}
}