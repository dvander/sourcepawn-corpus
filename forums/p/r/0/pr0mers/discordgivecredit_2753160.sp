#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "pr0mers"
#define PLUGIN_VERSION "1.50"

#include <sourcemod>
#include <sdktools>
new String:g_sFilePath[PLATFORM_MAX_PATH];

public void OnPluginStart()
{
	RegConsoleCmd("sm_discordcredit",krediver);
	RegConsoleCmd("sm_steamid",steamidss);
	BuildPath(Path_SM, g_sFilePath, sizeof(g_sFilePath), "logs/DiscordCreditSteamID/");
	if (!DirExists(g_sFilePath))
	{
		CreateDirectory(g_sFilePath, 511);
		
		if (!DirExists(g_sFilePath))
			SetFailState("Failed to create directory at /sourcemod/logs/DiscordCreditSteamID/ - Please manually create that path and reload this plugin.");
	}
	BuildPath(Path_SM, g_sFilePath, sizeof(g_sFilePath), "logs/DiscordCreditSteamID/peopletookcredit.txt");
	if(FileExists(g_sFilePath)==false){LogToFileEx(g_sFilePath, "done?");}
	 	
}
public Action krediver(int client, int args)
{
	decl String:szAuth[64];
	GetClientAuthString( client, szAuth, sizeof( szAuth ) );
	if(strlen(szAuth)==18){
		PrintToChat(client, "Wow you have a 8 digit steamid.");
		Format(szAuth, sizeof(szAuth), "%sX", szAuth);
	}
	//----------------------------------------
	new Handle:fileHandle = OpenFile( g_sFilePath, "r" );
	decl String:fileLine[256];
	int varmi = 0;
	char text1[64];
	char idkismi[64];
	char xkismi[64];
	char ikibs[64];
	char ucbs[64];
	char asal[64];
	char asalharic[54];
	char gercekadga[64];
	char gercekadgd[64];
	char gercekadgg[64];
	char sahteadga[64];
	char sahteadgd[64];
	char sahteadgg[64];
	char gercekx[64];
	GetCmdArgString(text1, sizeof(text1));
	if(strlen(text1) != 30){
		PrintToChat(client, "Your Code Is Wrong.");
		CloseHandle( fileHandle );
		return;
	}

	strcopy(idkismi, sizeof(idkismi), substr(text1, 0, 20));
	strcopy(xkismi, sizeof(xkismi), substr(text1, 19, 2));
	strcopy(ikibs, sizeof(ikibs), substr(text1, 20, 3));
	strcopy(ucbs, sizeof(ucbs), substr(text1, 22, 4));
	strcopy(asal, sizeof(asal), substr(text1, 25, 2));
	strcopy(asalharic, sizeof(asalharic), substr(text1, 26, 2));
	strcopy(gercekadga, sizeof(gercekadga), substr(text1, 11, 2));
	strcopy(gercekadgd, sizeof(gercekadgd), substr(text1, 14, 2));
	strcopy(gercekadgg, sizeof(gercekadgg), substr(text1, 17, 2));
	strcopy(sahteadga, sizeof(sahteadga), substr(text1, 27, 2));
	strcopy(sahteadgd, sizeof(sahteadgd), substr(text1, 28, 2));
	strcopy(sahteadgg, sizeof(sahteadgg), substr(text1, 29, 2));
	strcopy(gercekx, sizeof(gercekx), substr(szAuth, 8, 2));
	int ikibas = StringToInt(ikibs);
	int ucbas = StringToInt(ucbs);
	
	//PrintToChatAll(" %d %d %s", ikibas, ucbas,gercekx);
	 /*idkismi[512] = substr(text1, 0, 20);
	 xkismi[512]= substr(text1, 19, 2);
	 ikibs[512] = StringToInt(substr(text1, 20, 3));
	 ucbs[512] = StringToInt(substr(text1, 22, 4));
	 asal[512] = substr(text1, 25, 2);
	 asalharic[512] = substr(text1, 26, 2);
	 adga[512] = substr(text1, 10, 2);
	 adgd[512] = substr(text1, 13, 2);
	 adgg[512]= substr(text1, 16, 2);*/
	//PrintToChatAll("%s + %s + %s +%s + %s + %s + %s + %s + %s + %s + %s + %s + %s",idkismi,xkismi,gercekx,ikibs,ucbs,asal,asalharic,sahteadga,sahteadgd,sahteadgg , gercekadga,gercekadgd,gercekadgg);
	if(!StrEqual(substr(text1, 0, 20),szAuth)){
		PrintToChat(client, "Your Code Is Wrong.");
		CloseHandle( fileHandle );
		return;
	}
	int hepsidogru = 0;
	if(StrEqual(xkismi,gercekx) || ikibas%7 == 0 || ucbas%13 ==0){
		//PrintToChat(client, "dogru1");
		if(StrEqual(asal,"2") || StrEqual(asal,"3") || StrEqual(asal,"5")|| StrEqual(asal,"7")){
			//PrintToChat(client, "dogru2");
			if(StrEqual(asalharic,"1") || StrEqual(asalharic,"4") || StrEqual(asalharic,"6")|| StrEqual(asalharic,"8") || StrEqual(asalharic,"9")){
				//PrintToChat(client, "dogru3");
				if(StrEqual(sahteadga,gercekadga) && StrEqual(sahteadgg,gercekadgg) && StrEqual(sahteadgd,gercekadgd)){
					//PrintToChat(client, "dogru4");
					hepsidogru = 1;
				}
			}
		}
	}
	if(hepsidogru==0){
		PrintToChat(client, "Your Code Is Wrong.");
		CloseHandle( fileHandle );
		return;
	}
	while( !IsEndOfFile( fileHandle ) && ReadFileLine( fileHandle, fileLine, sizeof( fileLine ) ) )
	{
	    TrimString( fileLine );
	    //PrintToChatAll("%s + %s + %s", fileLine,fileLine[25],fileLine[2]);
	    //PrintToChatAll("%s", substr(fileLine, 25, 21));
	    if(StrEqual(fileLine[25] , szAuth)){
	   		varmi = 1;
	   		PrintToChat(client,"You Already Claimed Your Gift You Can't Take Another One.");
	   		CloseHandle( fileHandle );
	   		return;
	   	}
	    // CODE
	}
	if(varmi==0){
		LogToFileEx(g_sFilePath, szAuth);
		GetClientAuthString( client, szAuth, sizeof( szAuth ) );
		PrintToChat(client, "Your Credit Has Been Given");
		ServerCommand("sm_krediver  \"#%s\" 200000", szAuth);
	}
	CloseHandle( fileHandle ); 	
}
public Action steamidss(int client, int args)
{
	decl String:szAuth[64];
	GetClientAuthString( client, szAuth, sizeof( szAuth ) );
	PrintToChat(client,"%s", szAuth);
}
//--------------------------------------
stock char substr(char[] inpstr, int startpos, int len=-1)
{
    char outstr[512];

    if (len == -1)
    {
        strcopy(outstr, sizeof(outstr), inpstr[startpos]);
    }
    
    else
    {
        strcopy(outstr, len, inpstr[startpos]);
        outstr[len] = 0;
    }

    return outstr; 
}