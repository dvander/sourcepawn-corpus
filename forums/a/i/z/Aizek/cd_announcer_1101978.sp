#include <sourcemod>
#include <sdktools_sound>
#include "geoip.inc"

#pragma semicolon 1

#define CD_VERSION "2.9"

new Handle:PrintMode		= INVALID_HANDLE;
new Handle:PrintModeLog		= INVALID_HANDLE;
new Handle:ShowAll 		= INVALID_HANDLE;
new Handle:Sound		= INVALID_HANDLE;
new Handle:PrintCountry		= INVALID_HANDLE;
new Handle:ShowAdmins		= INVALID_HANDLE;
new Handle:CountryNameType	= INVALID_HANDLE;
new Handle:SoundFile		= INVALID_HANDLE;
new Handle:Logging		= INVALID_HANDLE;
new Handle:LogFile		= INVALID_HANDLE;
new Handle:File			= INVALID_HANDLE;
new log = -1;

public Plugin:myinfo = 
{
	name = "CD Announcer",
	author = "Fredd, gH0sTy, MOPO3KO",
	description = "",
	version = CD_VERSION,
	url = "www.sourcemod.net"
}

public OnPluginStart()
{
	LoadTranslations( "cdannouncer.phrases" );
	CreateConVar( "cd_announcer_version", CD_VERSION, "Connect/Disconnect Announcer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY );
	
	PrintMode	=	CreateConVar( "cd_mode", 	"1",	"1 = by SteamId, 2 = by Ip, 3 = ip and SteamId, 4 = No ip and SteamId (Def 1)",0, true, 1.0, true, 4.0);
	PrintModeLog	=	CreateConVar( "cd_mode_log", 	"1",	"1 = by SteamId, 2 = by Ip, 3 = ip and SteamId, 4 = No ip and SteamId (Def 1)",0, true, 1.0, true, 4.0);
	ShowAll		= 	CreateConVar( "cd_showall",	"1",	"1 = show all(connects, and disconnects), 2 = show connects only, 3 = show disconnects only",0, true, 1.0, true, 3.0);
	Sound		=	CreateConVar( "cd_sound", 	"1",	"Toggles sound on and off (Def 1 = on)" ,0, true, 0.0, true, 1.0);
	PrintCountry	=	CreateConVar( "cd_printcountry", "1",	"turns on/off priting country names 0 = off, 1= on (Def 1)",0, true, 0.0, true, 1.0);
	ShowAdmins	= 	CreateConVar( "cd_showadmins", 	"1",	"Shows Admins on connect/disconnect, 0= don't show, 1 = show (Def 1)",0, true, 0.0, true, 1.0);
	CountryNameType =	CreateConVar( "cd_country_type","1",	"country name print type 1 = print shortname, 2 = print full name(Def 1)",0, true, 1.0, true, 2.0);
	SoundFile	=	CreateConVar( "cd_sound_file",	"buttons/blip1.wav","Sound file location to be played on a connect/disconnect under the sounds directory (Def =buttons/blip1.wav)" );
	Logging		=	CreateConVar( "cd_loggin",	"1",	"turns on and off logging of connects and disconnect to a log file 1= on  2 = on only log annoucers 0 = off (Def 1)",0, true, 0.0, true, 2.0);
	LogFile		=	CreateConVar( "cd_logfile",	"data/cd_logs.log", "location of the log file relative to the sourcemod folder" );
	HookConVarChange(Logging, IsLogging);

	AutoExecConfig(true, "cd_announcer_cfgs");
}

public IsLogging(Handle:convar, const String:oldValue[], const String:newValue[])
{
	log = StringToInt(newValue);
	LogOnOff();
}

public LogOnOff()
{
	decl String:Time[21];
	FormatTime(Time, sizeof(Time), "%m/%d/%y - %I:%M:%S", -1) ;

	if (log > 0) {
		if(File != INVALID_HANDLE) return;

		decl String:iLogFileLoc[PLATFORM_MAX_PATH];

		GetConVarString( LogFile, iLogFileLoc, sizeof( iLogFileLoc ) );
		BuildPath( Path_SM, iLogFileLoc, sizeof( iLogFileLoc ), iLogFileLoc);
		File = OpenFile( iLogFileLoc, "a" );
		
		if(File == INVALID_HANDLE) {
			LogMessage("%t %s","File Not Created",iLogFileLoc );
			log = 0;
			SetConVarInt(Logging,0,false,false);
		}
		else {
			LogMessage("%t","Start Log");
			WriteFileLine(File,"[%s] %t", Time, "Start Log");
			FlushFile(File);
		}
	} else {
		if(File != INVALID_HANDLE) {
			LogMessage("%t", "End Log");
			WriteFileLine(File,"[%s] %t", Time, "End Log");
			FlushFile(File);
			CloseHandle(File);
			File = INVALID_HANDLE;
		}
	}
}

public OnConfigsExecuted()
{
	if(log == -1) {
		log = GetConVarInt(Logging);
		LogOnOff();
	}
}

public OnMapStart()
{
	decl String:FileLocation[PLATFORM_MAX_PATH];
	GetConVarString( SoundFile, FileLocation, sizeof(FileLocation));
	if(FileLocation[0]!=0) {
		if(FileExists(FileLocation)) PrecacheSound(FileLocation,true);
		else LogMessage("%t %s","File Not Found",FileLocation);
	}
}

public OnPluginEnd()
{
	log = 0;
	LogOnOff();
}

public WriteLogConnect(String:Time[], String:gName[], String:gCountry[], String:gAuth[], String:gIp[])
{
	switch(GetConVarInt(PrintModeLog)) {
		case 1: {
			switch(GetConVarInt(PrintCountry)) {
				case 0: WriteFileLine(File,"[%s] %s[%s] connected", Time, gName, gAuth);
				case 1: WriteFileLine(File,"[%s] %s(%s)[%s] connected", Time, gName, gCountry, gAuth);
			}	
		}
		case 2: {	
			switch(GetConVarInt(PrintCountry)) {
				case 0: WriteFileLine(File,"[%s] %s[%s] connected", Time, gName, gIp);
				case 1: WriteFileLine(File,"[%s] %s(%s)[%s] connected", Time, gName, gCountry, gIp);
			}	
		}
		case 3: {
			switch(GetConVarInt(PrintCountry)) {
				case 0: WriteFileLine(File,"[%s] %s[%s][%s] connected", Time, gName, gAuth, gIp);
				case 1: WriteFileLine(File,"[%s] %s(%s)[%s][%s] connected", Time, gName, gCountry, gAuth, gIp);
			}
		}
		case 4: {
			switch(GetConVarInt(PrintCountry)) {
				case 0: WriteFileLine(File,"[%s] %s connected", Time, gName);
				case 1: WriteFileLine(File,"[%s] %s(%s) connected", Time, gName, gCountry);
			}
		}
	}
        FlushFile(File);
}

public PrintLogConnect(String:Time[], String:gName[], String:gCountry[], String:gAuth[], String:gIp[])
{
	switch(GetConVarInt(PrintMode)) {
		case 1: {
			switch(GetConVarInt(PrintCountry)) {
				case 0: PrintToChatAll("%t", "Connected_Auth_1", gName, gAuth);
				case 1: PrintToChatAll("%t", "Connected_Auth_2", gName, gCountry, gAuth);
			}	
		}
		case 2:	{	
			switch(GetConVarInt(PrintCountry)) {
				case 0: PrintToChatAll("%t", "Connected_Ip_1", gName, gIp);
				case 1: PrintToChatAll("%t", "Connected_Ip_2", gName, gCountry, gIp);
			}	
		}
		case 3: {
			switch(GetConVarInt(PrintCountry)) {
				case 0: PrintToChatAll("%t", "Connected_1", gName, gAuth, gIp);
				case 1: PrintToChatAll("%t", "Connected_2", gName, gCountry, gAuth, gIp);
			}
		}
		case 4: {
			switch(GetConVarInt(PrintCountry)) {
				case 0: PrintToChatAll("%t", "Connected_Country_1", gName);
				case 1: PrintToChatAll("%t", "Connected_Country_2", gName, gCountry);
			}
		}
	}
}

public OnClientPostAdminCheck(client)
{
	if(IsFakeClient(client)) return;
	if(GetConVarInt(ShowAll) == 3) return;
	
	decl String:Time[21],
	     String:iFile[PLATFORM_MAX_PATH],
		 String:gCountry[46],
	     String:gName[MAX_NAME_LENGTH+1],
		 String:gIp[16],
		 String:gAuth[21];
	
	if(GetUserAdmin(client) != INVALID_ADMIN_ID && GetConVarInt(ShowAdmins) == 0) return;

	GetConVarString(SoundFile, iFile, sizeof(iFile));	
	GetClientName(client, gName, MAX_NAME_LENGTH);
	GetClientIP(client, gIp, sizeof(gIp));
	GetClientAuthString(client, gAuth, sizeof(gAuth));
	
	switch(GetConVarInt(CountryNameType))
	{
		case 1: {
                        decl String:gCountryS[3];
			GeoipCode2(gIp, gCountryS);
			strcopy(gCountry,46,gCountryS);
		}
		case 2: {
			GeoipCountry(gIp, gCountry, sizeof(gCountry));
		}
	}
	
	if(strlen(gCountry) == 0) Format(gCountry,sizeof(gCountry),"%t","Network");
	
	FormatTime(Time, sizeof( Time ), "%m/%d/%y - %I:%M:%S", -1);

	if(GetConVarInt(Sound) == 1) EmitSoundToAll(iFile);
			
	switch(log) {
		case 0: PrintLogConnect(Time, gName, gCountry, gAuth, gIp);
		case 1: {
			PrintLogConnect(Time, gName, gCountry, gAuth, gIp);
			WriteLogConnect(Time, gName, gCountry, gAuth, gIp);
			}
		case 2:	WriteLogConnect(Time, gName, gCountry, gAuth, gIp);
	}
}

public PrintLogDisconnect(String:Time[], String:gName[], String:gCountry[], String:gAuth[], String:gIp[])
{
	switch(GetConVarInt(PrintMode)) {
		case 1: {
			switch(GetConVarInt(PrintCountry)) {
				case 0: PrintToChatAll("%t", "Disconnected_Auth_1", gName, gAuth);
				case 1: PrintToChatAll("%t", "Disconnected_Auth_2", gName, gCountry, gAuth);
			}	
		}
		case 2:	{	
			switch(GetConVarInt(PrintCountry)) {
				case 0: PrintToChatAll("%t", "Disconnected_Ip_1", gName, gIp);
				case 1: PrintToChatAll("%t", "Disconnected_Ip_2", gName, gCountry, gIp);
			}	
		}
		case 3: {
			switch(GetConVarInt(PrintCountry)) {
				case 0: PrintToChatAll("%t", "Disconnected_1", gName, gAuth, gIp);
				case 1: PrintToChatAll("%t", "Disconnected_2", gName, gCountry, gAuth, gIp);
			}
		}
		case 4: {
			switch(GetConVarInt(PrintCountry)) {
				case 0: PrintToChatAll("%t", "Disconnected_Country_1", gName);
				case 1: PrintToChatAll("%t", "Disconnected_Country_2", gName, gCountry);
			}
		}
	}
}

public WriteLogDisconnect(String:Time[], String:gName[], String:gCountry[], String:gAuth[], String:gIp[])
{
	switch(GetConVarInt(PrintModeLog)) {
		case 1: {
			switch(GetConVarInt(PrintCountry)) {
				case 0: WriteFileLine(File,"[%s] %s[%s] disconnected", Time, gName, gAuth);
				case 1: WriteFileLine(File,"[%s] %s(%s)[%s] disconnected", Time, gName, gCountry, gAuth);
			}	
		}
		case 2:	{	
			switch(GetConVarInt(PrintCountry)) {
				case 0: WriteFileLine(File,"[%s] %s[%s] disconnected", Time, gName, gIp);
				case 1: WriteFileLine(File,"[%s] %s(%s)[%s] disconnected", Time, gName, gCountry, gIp);
			}	
		}
		case 3: {
			switch(GetConVarInt(PrintCountry)) {
				case 0: WriteFileLine(File,"[%s] %s[%s][%s] disconnected", Time, gName, gAuth, gIp);
				case 1: WriteFileLine(File,"[%s] %s(%s)[%s][%s] disconnected", Time, gName, gCountry, gAuth, gIp);
			}
		}
		case 4: {
			switch(GetConVarInt(PrintCountry)) {
				case 0: WriteFileLine(File,"[%s] %s disconnected", Time, gName);
				case 1: WriteFileLine(File,"[%s] %s(%s) disconnected", Time, gName, gCountry);
			}
		}
	}
	FlushFile(File);
}

public OnClientDisconnect(client)
{
	if(IsFakeClient(client)) return;
	if(GetConVarInt(ShowAll) == 2) return;
	
	decl String:Time[21],
	     String:iFile[PLATFORM_MAX_PATH],
             String:gCountry[46],
	     String:gName[MAX_NAME_LENGTH+1],
	     String:gIp[16],
	     String:gAuth[21];
	
	if(GetUserAdmin(client) != INVALID_ADMIN_ID && GetConVarInt(ShowAdmins) == 0) return;

	GetConVarString(SoundFile, iFile, sizeof(iFile));	
	GetClientName(client, gName, MAX_NAME_LENGTH);
	GetClientIP(client, gIp, sizeof(gIp));
	GetClientAuthString(client, gAuth, sizeof(gAuth));
	
	switch(GetConVarInt(CountryNameType))
	{
		case 1: {
                        decl String:gCountryS[3];
			GeoipCode2(gIp, gCountryS);
			strcopy(gCountry,46,gCountryS);
		}
		case 2: {
			GeoipCountry(gIp, gCountry, sizeof(gCountry));
		}
	}
	
	if(strlen(gCountry) == 0) Format(gCountry,sizeof(gCountry),"%t","Network");

	FormatTime(Time, sizeof( Time ), "%m/%d/%y - %I:%M:%S", -1);

	if(GetConVarInt(Sound) == 1) EmitSoundToAll(iFile);

	switch(log) {
		case 0: PrintLogDisconnect(Time, gName, gCountry, gAuth, gIp);
		case 1: {
			PrintLogDisconnect(Time, gName, gCountry, gAuth, gIp);
			WriteLogDisconnect(Time, gName, gCountry, gAuth, gIp);
			}
		case 2: WriteLogDisconnect(Time, gName, gCountry, gAuth, gIp);
	}
}
