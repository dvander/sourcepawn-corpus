#include <sourcemod>
#include <sdktools_sound>
#include <geoipcity>

#pragma semicolon 1

#define CD_VERSION "2.3.1"

new Handle:PrintMode 		= INVALID_HANDLE;
new Handle:ShowAll 		= INVALID_HANDLE;
new Handle:Sound		= INVALID_HANDLE;
new Handle:PrintCountry		= INVALID_HANDLE;
new Handle:ShowAdmins		= INVALID_HANDLE;
new Handle:CountryNameType	= INVALID_HANDLE;
new Handle:SoundFile		= INVALID_HANDLE;
new Handle:Logging		= INVALID_HANDLE;
new Handle:LogFile		= INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "CD Announcer++",
	author = "Fredd edited by The Team Ghost",
	description = "",
	version = CD_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=302245"
}
public OnMapStart()
{
	AutoExecConfig(true, "cd_announcer_cfgs");
	
	decl String:FileLocation[PLATFORM_MAX_PATH];
	GetConVarString( SoundFile, FileLocation, sizeof( FileLocation ) );
	PrecacheSound( FileLocation );
	
	if( GetConVarInt(Logging) > 0 )
	{
		decl String:iLogFileLoc[PLATFORM_MAX_PATH], String:LogFileLoc[PLATFORM_MAX_PATH];
		
		GetConVarString( LogFile, iLogFileLoc, sizeof( iLogFileLoc ) );
		Format( LogFileLoc, sizeof( LogFileLoc ), "addons/sourcemod/%s", iLogFileLoc );
		
		if( !FileExists( LogFileLoc ) )
		{
			decl String:Path[PLATFORM_MAX_PATH];
			decl String:Time[21];
			
			FormatTime( Time, sizeof( Time ), "%m/%d/%y - %I:%M:%S", -1) ;
			
			LogMessage( "%s %t", LogFile, "File Not Found" );
			BuildPath( Path_SM,Path, sizeof( Path ), LogFileLoc );
			LogMessage( "%s has been created!", Path );
			
			new Handle:File = OpenFile( Path, "a" );
			WriteFileLine( File,"[%s] %t", Time, "Log Started" );
			CloseHandle( File );
		}
	}
}

public OnPluginStart()
{
	LoadTranslations( "cdannouncer.phrases" );
	CreateConVar( "cd_announcer_version", CD_VERSION, "Connect/Disconnect Announcer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY );
	
	PrintMode	=	CreateConVar( "cd_mode", 	"1",	"1 = by SteamId, 2 = by Ip, 3 = ip and SteamId (Def 1)" );
	ShowAll		= 	CreateConVar( "cd_showall",	"1",	"1 = show all(connects, and disconnects), 2 = show connects only, 3 = show disconnects only" );
	Sound		=	CreateConVar( "cd_sound", 	"1",	"Toggles sound on and off (Def 1 = on)" );
	PrintCountry	=	CreateConVar( "cd_printcountrycity", "1",	"Country Print mode: 0 = off, 1 = country, 2 = country and city (Def 1)" );
	ShowAdmins	= 	CreateConVar( "cd_showadmins", 	"1",	"Shows Admins on connect/disconnect, 0= don't show, 1 = show (Def 1)" );
	CountryNameType =	CreateConVar( "cd_country_type","1",	"country name print type 1 = print shortname, 2 = print full name, (3 = country short with city), 4 = country long with city (Def 1)" );
	SoundFile	=	CreateConVar( "cd_sound_file",	"buttons/blip1.wav","Sound file location to be played on a connect/disconnect under the sounds directory (Def =buttons/blip1.wav)" );
	Logging		=	CreateConVar( "cd_loggin",	"1",	"turns on and off logging of connects and disconnect to a log file 1= on  2 = on only log annoucers 0 = off (Def 1)" );
	LogFile		=	CreateConVar( "cd_logfile",	"data/cd_logs.log", "location of the log file relative to the sourcemod folder" );
}

bool:IsLanIP( String:src[16] )
{
	decl String:ip4[4][4];
	new ipnum;

	if(ExplodeString(src, ".", ip4, 4, 4) == 4)
	{
		ipnum = StringToInt(ip4[0])*65536 + StringToInt(ip4[1])*256 + StringToInt(ip4[2]);
		
		if((ipnum >= 655360 && ipnum < 655360+65535) || (ipnum >= 11276288 && ipnum < 11276288+4095) || (ipnum >= 12625920 && ipnum < 12625920+255))
		{
			return true;
		}
	}

	return false;
}

public OnClientPostAdminCheck( client )
{
	if( IsFakeClient( client ) )
		return;
		
	if( GetConVarInt( ShowAll ) == 3 )
		return;
	
	decl String:gName[MAX_NAME_LENGTH+1], String:iFile[256];
	decl String:gAuth[21];
	decl String:Time[21], String:iLogFileLoc[PLATFORM_MAX_PATH], String:LogFileLoc[PLATFORM_MAX_PATH];
	
	FormatTime( Time, sizeof( Time ), "%m/%d/%y - %I:%M:%S", -1 );
		
	new PrintCountryNameMode	= GetConVarInt( CountryNameType );
	new PlaySound 				= GetConVarInt( Sound );
	new Code 					= GetConVarInt( PrintCountry );
	new Admin 					= GetConVarInt( ShowAdmins );
	new Log 					= GetConVarInt( Logging );
	GetConVarString( SoundFile, iFile, sizeof( iFile ) );
	GetConVarString( LogFile, iLogFileLoc, sizeof( iLogFileLoc ) );
	Format( LogFileLoc, sizeof( LogFileLoc ), "addons/sourcemod/%s", iLogFileLoc );
	
	new AdminId:AdminID = GetUserAdmin( client );
	
	if( AdminID != INVALID_ADMIN_ID && Admin == 0 )
		return;
	
	decl String:ip[16];
	decl String:city[46];
	decl String:region[46];
	decl String:country[46];
	decl String:ccode[3];
	decl String:ccode3[4];
	new bool:b_IsLanIp;
	
	GetClientName( client, gName, MAX_NAME_LENGTH );
	GetClientIP(client, ip, sizeof(ip)); 
		
	//detect LAN ip
	b_IsLanIp = IsLanIP( ip );
	GetClientAuthString( client, gAuth, sizeof( gAuth ) );
	
	switch( PrintCountryNameMode )
	{
		case 1:
		{
			if( !GeoipGetRecord(ip, city, region, country, ccode, ccode3) )
			{
				if(b_IsLanIp)
				{
					Format( city, sizeof(city), "%T", "LAN City Desc", LANG_SERVER );
					Format( ccode, sizeof(ccode), "%T", "LAN Country Short", LANG_SERVER );
					Format(country, sizeof(country), "%s", ccode);
				}
				else
				{
					Format( city, sizeof(city), "%T", "Unknown City Desc", LANG_SERVER );
					Format( ccode, sizeof(ccode), "%T", "Unknown Country Short", LANG_SERVER );
					Format(country, sizeof(country), "%s", ccode);
				}
			}
		}
		case 2:
		{
			if( !GeoipGetRecord(ip, city, region, country, ccode, ccode3) )
			{
				if(b_IsLanIp)
				{
					Format( country, sizeof(country), "%T", "LAN Country Desc", LANG_SERVER );
				}
				else
				{
					Format( country, sizeof(country), "%T", "Unknown Country Desc", LANG_SERVER );
				}
			}
		}
		case 3:
		{
			if( !GeoipGetRecord(ip, city, region, country, ccode, ccode3) )
			{
				if(b_IsLanIp)
				{
					Format( city, sizeof(city), "%T", "LAN City Desc", LANG_SERVER );
					Format( ccode, sizeof(ccode), "%T", "LAN Country Short", LANG_SERVER );
					Format(country, sizeof(country), "%s", ccode);
				}
				else
				{
					Format( city, sizeof(city), "%T", "Unknown City Desc", LANG_SERVER );
					Format( ccode, sizeof(ccode), "%T", "Unknown Country Short", LANG_SERVER );
					Format(country, sizeof(country), "%s", ccode);
				}
			}
		}
		case 4:
		{
			if( !GeoipGetRecord(ip, city, region, country, ccode, ccode3) )
			{
				if(b_IsLanIp)
				{
					Format( city, sizeof(city), "%T", "LAN City Desc", LANG_SERVER );
					Format( country, sizeof(country), "%T", "LAN Country Desc", LANG_SERVER );
				}
				else
				{
					Format( city, sizeof(city), "%T", "Unknown City Desc", LANG_SERVER );
					Format( country, sizeof(country), "%T", "Unknown Country Desc", LANG_SERVER );
				}
			}
		}
	}
	
	// Fallback for unknown/empty location strings
	if( StrEqual( city, "" ) )
	{
		Format( city, sizeof(city), "%T", "Unknown City Desc", LANG_SERVER );
	}
	if( StrEqual( country, "" ) )
	{
		Format( country, sizeof(country), "%T", "Unknown Country Desc", LANG_SERVER );
	}
	if( StrEqual( ccode, "" ) )
	{
		Format( ccode, sizeof(ccode), "%T", "Unknown Country Short", LANG_SERVER );
	}
	
	new Handle:File = OpenFile( LogFileLoc, "a" );
	if( File == INVALID_HANDLE && Log > 0 )
	{
		LogError( "%t", "File Not Created" );
		return;
	}
	
	switch( GetConVarInt( PrintMode ) )
	{
		case 1:
		{
			if( PlaySound == 1 )
				EmitSoundToAll( iFile );
			
			switch( Code )
			{
				case 0:
				{
					switch( Log )
					{
						case 0: PrintToChatAll( "%t", "Connected_Auth_1", gName, gAuth );
						case 1:
						{
							PrintToChatAll( "%t", "Connected_Auth_Mini", gName, gAuth );
							WriteFileLine( File,"[%s] %s[%s] connected", Time, gName, gAuth );
						}
						case 2: WriteFileLine( File,"[%s] %s[%s] connected", Time, gName, gAuth );
					}
				}
				case 1: 
				{
					switch( Log )
					{
						case 0:	PrintToChatAll( "%t", "Connected_Auth_2", gName, country, gAuth );
						case 1:
						{
							PrintToChatAll( "%t", "Connected_Auth_2", gName, country, gAuth );
							WriteFileLine( File,"[%s] %s(%s)[%s] connected", Time, gName, country, gAuth );
						}
						case 2:	WriteFileLine( File,"[%s] %s(%s)[%s] connected", Time, gName, country, gAuth );
					}
				}
				// I used Country On/Off switch as a way to add city support into the plugin
				case 2: 
				{
					switch( Log )
					{
						case 0:	PrintToChatAll( "%t", "Connected_Auth_3", gName, city, country, gAuth );
						case 1:
						{
							PrintToChatAll( "%t", "Connected_Auth_3", gName, city, country, gAuth );
							WriteFileLine( File,"[%s] %s(%s ,%s)[%s] connected", Time, gName, city, country, gAuth );
						}
						case 2:	WriteFileLine( File,"[%s] %s(%s, %s)[%s] connected", Time, gName, city, country, gAuth );
					}
				}
			}	
		}
		case 2:
		{	
			if( PlaySound == 1 )
				EmitSoundToAll( iFile );
			
			switch( Code )
			{
				case 0:
				{
					switch( Log )
					{
						case 0: PrintToChatAll( "%t", "Connected_Ip_1", gName, ip );
						case 1: 
						{
							PrintToChatAll( "%t", "Connected_Ip_1", gName, ip );
							WriteFileLine( File,"[%s] %s[%s] connected", Time, gName, ip );
						}
						case 2: WriteFileLine( File,"[%s] %s[%s] connected", Time, gName, ip );
					}					
				}
				case 1: 
				{
					switch( Log )
					{
						case 0:	PrintToChatAll( "%t", "Connected_Ip_2", gName, country, ip );
						case 1:
						{
							PrintToChatAll( "%t", "Connected_Ip_2", gName, country, ip );
							WriteFileLine( File,"[%s] %s(%s)[%s] connected", Time, gName, country, ip );
						}
						case 2:	WriteFileLine( File,"[%s] %s(%s)[%s] connected", Time, gName, country, ip );
					}
				}
				// IP based join message
				case 2: 
				{
					switch( Log )
					{
						case 0:	PrintToChatAll( "%t", "Connected_Auth_3", gName, city, country, ip);
						case 1:
						{
							PrintToChatAll( "%t", "Connected_Auth_3", gName, city, country, ip);
							WriteFileLine( File,"[%s] %s(%s ,%s)[%s] connected", Time, gName, city, country, ip);
						}
						case 2:	WriteFileLine( File,"[%s] %s(%s, %s)[%s] connected", Time, gName, city, country, ip);
					}
				}
			}	
		}
		case 3:
		{
			if( PlaySound == 1 )
				EmitSoundToAll( iFile );
			
			switch( Code )
			{
				case 0: 
				{
					switch( Log )
					{
						case 0:	PrintToChatAll( "%t", "Connected_1", gName, gAuth, ip );
						case 1:
						{
							PrintToChatAll( "%t", "Connected_1", gName, gAuth, ip );
							WriteFileLine( File,"[%s] %s[%s][%s] connected", Time, gName, gAuth, ip );
						}
						case 2:	WriteFileLine( File,"[%s] %s[%s][%s] connected", Time, gName, gAuth, ip );
					}
				}
				case 1: 
				{
					switch( Log )
					{
						case 0: PrintToChatAll( "%t", "Connected_2", gName, country, gAuth, ip );
						case 1:
						{
							PrintToChatAll( "%t", "Connected_2", gName, country, gAuth, ip );
							WriteFileLine( File,"[%s] %s(%s)[%s][%s] connected", Time, gName, country, gAuth, ip );
						}
						case 2:	WriteFileLine( File,"[%s] %s(%s)[%s][%s] connected", Time, gName, country, gAuth, ip );
					}						
				}
				// SteamID and IP based connect message
				case 2: 
				{
					switch( Log )
					{
						case 0:	PrintToChatAll( "%t", "Connected_Auth_3", gName, city, country, gAuth, ip);
						case 1:
						{
							PrintToChatAll( "%t", "Connected_Auth_3", gName, city, country, gAuth, ip);
							WriteFileLine( File,"[%s] %s(%s ,%s)[ID: %s & IP: %s] connected", Time, gName, city, country, gAuth, ip);
						}
						case 2:	WriteFileLine( File,"[%s] %s(%s, %s)[ID: %s & IP: %s] connected", Time, gName, city, country, gAuth, ip);
					}
				}
			}
		}
	}
	if( File != INVALID_HANDLE )
		CloseHandle( File );
	
	return;
}
public OnClientDisconnect( client )
{
	if( IsFakeClient( client ) )
		return;
		
	if( GetConVarInt( ShowAll ) == 2 )
		return;
		
	decl String:gName[MAX_NAME_LENGTH+1], String:iFile[256];
	decl String:gAuth[21];
	decl String:Time[21],  String:iLogFileLoc[PLATFORM_MAX_PATH], String:LogFileLoc[PLATFORM_MAX_PATH];
	
	FormatTime( Time, sizeof( Time ), "%m/%d/%y - %I:%M:%S", -1 ) ;
		
	new PrintCountryNameMode	= GetConVarInt( CountryNameType );
	new PlaySound 				= GetConVarInt( Sound );
	new Code 					= GetConVarInt( PrintCountry );
	new Admin 					= GetConVarInt( ShowAdmins );
	new Log						= GetConVarInt( Logging );
	GetConVarString( SoundFile, iFile, sizeof( iFile ) );
	GetConVarString( LogFile, iLogFileLoc, sizeof( iLogFileLoc ) );
	Format( LogFileLoc, sizeof( LogFileLoc ), "addons/sourcemod/%s", iLogFileLoc );
	
	new AdminId:AdminID = GetUserAdmin( client );
	
	if( AdminID != INVALID_ADMIN_ID && Admin == 0 )
		return;
		
	decl String:ip[16];
	decl String:city[46];
	decl String:region[46];
	decl String:country[46];
	decl String:ccode[3];
	decl String:ccode3[4];
	new bool:b_IsLanIp;
	
	GetClientName( client, gName, MAX_NAME_LENGTH );
	GetClientIP(client, ip, sizeof(ip)); 
		
	//detect LAN ip
	b_IsLanIp = IsLanIP( ip );
	GetClientAuthString( client, gAuth, sizeof( gAuth ) );
	
	switch( PrintCountryNameMode )
	{
		case 1:
		{
			if( !GeoipGetRecord(ip, city, region, country, ccode, ccode3) )
			{
				if(b_IsLanIp)
				{
					Format( city, sizeof(city), "%T", "LAN City Desc", LANG_SERVER );
					Format( ccode, sizeof(ccode), "%T", "LAN Country Short", LANG_SERVER );
					Format(country, sizeof(country), "%s", ccode);
				}
				else
				{
					Format( city, sizeof(city), "%T", "Unknown City Desc", LANG_SERVER );
					Format( ccode, sizeof(ccode), "%T", "Unknown Country Short", LANG_SERVER );
					Format(country, sizeof(country), "%s", ccode);
				}
			}
		}
		case 2:
		{
			if( !GeoipGetRecord(ip, city, region, country, ccode, ccode3) )
			{
				if(b_IsLanIp)
				{
					Format( country, sizeof(country), "%T", "LAN Country Desc", LANG_SERVER );
				}
				else
				{
					Format( country, sizeof(country), "%T", "Unknown Country Desc", LANG_SERVER );
				}
			}
		}
		case 3:
		{
			if( !GeoipGetRecord(ip, city, region, country, ccode, ccode3) )
			{
				if(b_IsLanIp)
				{
					Format( city, sizeof(city), "%T", "LAN City Desc", LANG_SERVER );
					Format( ccode, sizeof(ccode), "%T", "LAN Country Short", LANG_SERVER );
					Format(country, sizeof(country), "%s", ccode);
				}
				else
				{
					Format( city, sizeof(city), "%T", "Unknown City Desc", LANG_SERVER );
					Format( ccode, sizeof(ccode), "%T", "Unknown Country Short", LANG_SERVER );
					Format(country, sizeof(country), "%s", ccode);
				}
			}
		}
		case 4:
		{
			if( !GeoipGetRecord(ip, city, region, country, ccode, ccode3) )
			{
				if(b_IsLanIp)
				{
					Format( city, sizeof(city), "%T", "LAN City Desc", LANG_SERVER );
					Format( country, sizeof(country), "%T", "LAN Country Desc", LANG_SERVER );
				}
				else
				{
					Format( city, sizeof(city), "%T", "Unknown City Desc", LANG_SERVER );
					Format( country, sizeof(country), "%T", "Unknown Country Desc", LANG_SERVER );
				}
			}
		}
	}
	
	// Fallback for unknown/empty location strings
	if( StrEqual( city, "" ) )
	{
		Format( city, sizeof(city), "%T", "Unknown City Desc", LANG_SERVER );
	}
	if( StrEqual( country, "" ) )
	{
		Format( country, sizeof(country), "%T", "Unknown Country Desc", LANG_SERVER );
	}
	if( StrEqual( ccode, "" ) )
	{
		Format( ccode, sizeof(ccode), "%T", "Unknown Country Short", LANG_SERVER );
	}
	
	new Handle:File = OpenFile( LogFileLoc, "a" );
	if( File == INVALID_HANDLE && Log > 0 )
	{
		LogError( "%t", "File Not Created" );
		return;
	}
	
	switch( GetConVarInt( PrintMode ) )
	{
		case 1:
		{
			if( PlaySound == 1 )
				EmitSoundToAll( iFile );
			
			switch( Code )
			{
				case 0:
				{
					switch( Log )
					{
						case 0: PrintToChatAll( "%t", "Disconnected_Auth_1", gName, gAuth );
						case 1:
						{
							PrintToChatAll( "%t", "Disconnected_Auth_Mini", gName, gAuth );
							WriteFileLine( File,"[%s] %s[%s] disconnected", Time, gName, gAuth );
						}
						case 2: WriteFileLine( File,"[%s] %s[%s] disconnected", Time, gName, gAuth );
					}
				}
				case 1: 
				{
					switch( Log )
					{
						case 0:	PrintToChatAll( "%t", "Disconnected_Auth_2", gName, country, gAuth );
						case 1:
						{
							PrintToChatAll( "%t", "Disconnected_Auth_2", gName, country, gAuth );
							WriteFileLine( File,"[%s] %s(%s)[%s] disconnected", Time, gName, country, gAuth );
						}
						case 2:	WriteFileLine( File,"[%s] %s(%s)[%s] disconnected", Time, gName, country, gAuth );
					}
				}
				// Disconnect messsage with city added to it
				case 2: 
				{
					switch( Log )
					{
						case 0:	PrintToChatAll( "%t", "Disconnected_Auth_3", gName, city, country, gAuth );
						case 1:
						{
							PrintToChatAll( "%t", "Disconnected_Auth_2", gName, city, country, gAuth );
							WriteFileLine( File,"[%s] %s(%s, %s)[%s] disconnected", Time, gName, city, country, gAuth );
						}
						case 2:	WriteFileLine( File,"[%s] %s(%s, %s)[%s] disconnected", Time, gName, city, country, gAuth );
					}
				}
			}	
		}
		case 2:
		{	
			if( PlaySound == 1 )
				EmitSoundToAll( iFile );
			
			switch( Code )
			{
				case 0: 
				{
					switch( Log )
					{
						case 0: PrintToChatAll( "%t", "Disconnected_Ip_1", gName, ip );
						case 1: 
						{
							PrintToChatAll( "%t", "Disconnected_Ip_1", gName, ip );
							WriteFileLine( File,"[%s] %s[%s] disconnected", Time, gName, ip );
						}
						case 2: WriteFileLine( File,"[%s] %s[%s] disconnected", Time, gName, ip );
					}					
				}
				case 1: 
				{
					switch( Log )
					{
						case 0:	PrintToChatAll( "%t", "Disconnected_Ip_2", gName, country, ip );
						case 1:
						{
							PrintToChatAll( "%t", "Disconnected_Ip_2", gName, country, ip );
							WriteFileLine( File,"[%s] %s(%s)[%s] disconnected", Time, gName, country, ip );
						}
						case 2:	WriteFileLine( File,"[%s] %s(%s)[%s] disconnected", Time, gName, country, ip );
					}
				}
				// IP based disconnect message
				case 2: 
				{
					switch( Log )
					{
						case 0:	PrintToChatAll( "%t", "Disconnected_Auth_3", gName, city, country, gAuth );
						case 1:
						{
							PrintToChatAll( "%t", "Disconnected_Auth_3", gName, city, country, gAuth );
							WriteFileLine( File,"[%s] %s(%s ,%s)[%s] disconnected", Time, gName, city, country, gAuth );
						}
						case 2:	WriteFileLine( File,"[%s] %s(%s, %s)[%s] disconnected", Time, gName, city, country, gAuth );
					}
				}
			}	
		}
		case 3:
		{
			if( PlaySound == 1 )
				EmitSoundToAll( iFile );
			
			switch( Code )
			{
				case 0: 
				{
					switch( Log )
					{
						case 0:	PrintToChatAll( "%t", "Disconnected_1", gName, gAuth, ip );
						case 1:
						{
							PrintToChatAll( "%t", "Disconnected_1", gName, gAuth, ip );
							WriteFileLine( File,"[%s] %s[%s][%s] disconnected", Time, gName, gAuth, ip );
						}
						case 2:	WriteFileLine( File,"[%s] %s[%s][%s] disconnected", Time, gName, gAuth, ip );
					}
				}
				case 1: 
				{
					switch( Log )
					{
						case 0: PrintToChatAll( "%t", "Disconnected_2", gName, country, gAuth, ip );
						case 1:
						{
							PrintToChatAll( "%t", "Disconnected_2", gName, country, gAuth, ip );
							WriteFileLine( File,"[%s] %s(%s)[%s][%s] disconnected", Time, gName, country, gAuth, ip );
						}
						case 2:	WriteFileLine( File,"[%s] %s(%s)[%s][%s] disconnected", Time, gName, country, gAuth, ip );
					}						
				}
				// SteamID and IP based disconnect message
				case 2: 
				{
					switch( Log )
					{
						case 0:	PrintToChatAll( "%t", "Disconnected_3", gName, city, country, gAuth, ip);
						case 1:
						{
							PrintToChatAll( "%t", "Disconnected_3", gName, city, country, gAuth, ip);
							WriteFileLine( File,"[%s] %s(%s ,%s)[ID: %s & IP: %s] disconnected", Time, gName, city, country, gAuth, ip);
						}
						case 2:	WriteFileLine( File,"[%s] %s(%s, %s)[ID: %s & IP: %s] disconnected", Time, gName, city, country, gAuth, ip);
					}
				}
			}
		}
	}
	if( File != INVALID_HANDLE )
		CloseHandle( File );
	
	return;
}
