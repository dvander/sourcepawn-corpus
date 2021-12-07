/**
 * adverts.sp
 * Adds adverts to the server
 */

#include <sourcemod>

#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo = 
{
	name = "Adverts",
	author = "Wiebbe",
	description = "Shows adverts on the map.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

#define MAXADVERTS 128

#define RED 0
#define GREEN 255
#define BLUE 0
#define ALPHA 255

new String:g_szModName[32];

new String:g_szAdverts[MAXADVERTS][192];


new Handle:g_hSmAdvertFile = INVALID_HANDLE;
new Handle:g_hMpFriendlyfire = INVALID_HANDLE;

new Handle:g_hMpTimelimit = INVALID_HANDLE;

new Handle:g_himAdvertTime = INVALID_HANDLE;
new Handle:g_himAdvertEnabled = INVALID_HANDLE;
new Handle:g_himAdvertMsgType = INVALID_HANDLE;
new Handle:g_hSmNextMap = INVALID_HANDLE;
new Handle:g_hAdvertTimer = INVALID_HANDLE;

new g_iCurrentAdvert = 0;
new g_iAdvertCount = 0;
new Float:g_fStartTime;


public OnPluginStart()
{
	g_hSmAdvertFile = CreateConVar("sm_adverts_file", "configs/adverts.ini", "Advert file to use. (Def configs/adverts.ini)");
	g_himAdvertTime = CreateConVar("sm_adverts_time", "300", "Duration between adverts. (In Seconds, Def. 300 seconds)");
	g_himAdvertEnabled = CreateConVar("sm_adverts_enabled", "1", "Enables/Disables the Advert system (Def. enabled");
	g_himAdvertMsgType = CreateConVar("sm_adverts_msgtype", "1", "What kind of message display should the Advert be? (1: Chat (Def.), 2:Hint, 3:Center Text, 4:Panel");

	g_hMpFriendlyfire = FindConVar("mp_friendlyfire")
	g_hMpTimelimit = FindConVar("mp_timelimit");

	GetGameFolderName(g_szModName, sizeof(g_szModName));	
	
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
}

public OnMapStart()
{

	decl String:szAdvertPath[256], String:szAdvertFile[64];

	GetConVarString(g_hSmAdvertFile, szAdvertFile, 64);

	BuildPath(Path_SM, szAdvertPath, sizeof(szAdvertPath), szAdvertFile);

	LogMessage("[Advert] Advert Path: %s", szAdvertPath);
	
	g_fStartTime = GetEngineTime();

	if(LoadSettings(szAdvertPath))
		CreateTimer(2.0, Timer_DelayStart);
	else
		LogMessage("[Adverts] Cannot find advert file, Adverts not active.");	
}

public OnMapEnd()
{
	if(g_hAdvertTimer != INVALID_HANDLE)
	{
		KillTimer(g_hAdvertTimer);
		g_hAdvertTimer = INVALID_HANDLE;
	}
}


public Action:Timer_DelayStart(Handle:timer)
{
	new iAdvertTime = GetConVarInt(g_himAdvertTime);

	g_iCurrentAdvert = 0;

	g_hSmNextMap = FindConVar("sm_nextmap");

	if(g_hAdvertTimer == INVALID_HANDLE) 
	{
		g_hAdvertTimer = CreateTimer(float(iAdvertTime), Timer_Advert, _, TIMER_REPEAT);
	}
	else
	{
		LogMessage("[Adverts] g_hAdvertTimer not INVALID_HANDLE in Timer_DelayStart! Why not? Check logs!");
	}


}

public Action:Timer_Advert(Handle:timer)
{

	new enabled = GetConVarInt(g_himAdvertEnabled);

	decl String:szAdvert[192], szDynAdvert[192];

	szAdvert = g_szAdverts[g_iCurrentAdvert];

	if (enabled == 1) {

		new type = GetConVarInt(g_himAdvertMsgType);			

		new maxplayers=GetMaxClients();
	
		for(new player=1;player<=maxplayers;player++)
		{
			if(IsClientConnected(player) && IsClientInGame(player))
			{

				szDynAdvert = ReplaceDynamics(szAdvert);

				switch (type)
				{
					case 2: SendHintText(player,"%s", szAdvert )
					case 3: PrintCenterText(player, "%s", szAdvert )
					case 4: SendTopMessage(player,RED,GREEN,BLUE,ALPHA, "%s", szAdvert )
					default: PrintToChat(player,"\x01\x04%s", szAdvert )



				}
			}


		}
		
		++g_iCurrentAdvert;

		if( g_iAdvertCount == g_iCurrentAdvert) {
			g_iCurrentAdvert = 0;
		}

	}

	return Plugin_Continue
}

ReplaceDynamics(String:szCurrentAd[192])
{
	decl String:sTimeleft[8], String:sFriendlyFire[4], String:sNextmap[32], String:sCurrentmap[32];

	//SET THE TIMELEFT
	new iMins, iSecs;
	new iTimeLeft = RoundToNearest(GetTimeLeft());
	
	iMins = iTimeLeft / 60;
	iSecs = iTimeLeft % 60;	

	Format(sTimeleft, 8, "%d:%02d", iMins, iSecs  );

	//REPLACE THE TIMELEFT DYNAMIC
	ReplaceString(szCurrentAd, 192, "{timeleft}", sTimeleft);

	//SET THE CURRENTMAP
	GetCurrentMap(sCurrentmap, sizeof(sCurrentmap))
	
	//REPLACE THE CURRENTMAP DYNAMIC
	ReplaceString(szCurrentAd, 192, "{currentmap}", sCurrentmap);

	//SET FRIENDLY FIRE
	Format(sFriendlyFire, 4,"%s", GetConVarInt(g_hMpFriendlyfire) ? "ON" : "OFF")

	//REPLACE THE FF DYNAMIC
	ReplaceString(szCurrentAd, 192, "{ff}", sFriendlyFire);


	if(g_hSmNextMap != INVALID_HANDLE)
	{
		GetConVarString(g_hSmNextMap, sNextmap, 31);

		ReplaceString(szCurrentAd, 192, "{nextmap}", sNextmap);
	}	

	return szCurrentAd;
}

//FUNCTION FROM MAPCHOOSER
LoadSettings(String:szFilename[])
{
	if (!FileExists(szFilename))
		return 0;

	new String:szText[192];
	
	new Handle:hAdvertFile = OpenFile(szFilename, "r");
	
	g_iAdvertCount = 0;
	
	while(g_iAdvertCount < MAXADVERTS && !IsEndOfFile(hAdvertFile))
	{
		ReadFileLine(hAdvertFile, szText, sizeof(szText));
		TrimString(szText);

		if (szText[0] != ';' && strcopy(g_szAdverts[g_iAdvertCount], sizeof(g_szAdverts[]), szText))
		{
			++g_iAdvertCount;
		}
	}

	return g_iAdvertCount;
}

//FUNCTION FROM EXLUDE MESSAGES
stock SendHintText(client,String:text[], any:...)
{
	new String:message[192];
	VFormat(message,191,text, 3);

	new len = strlen(message);
	
	if(len > 30)
	{
		new LastAdded=0;

		for(new i=0;i<len;i++)
		{
			if((message[i]==' ' && LastAdded > 30 && (len-i) > 10) || ((GetNextSpaceCount(text,i+1) + LastAdded)  > 34))
			{
				message[i] = '\n';
				LastAdded = 0;
			}
			else
				LastAdded++;
		}
	}

	new clients[2]
	clients[0]=client
	
	new Handle:HintMessage = StartMessage("HintText", clients, 1, USERMSG_RELIABLE)
	BfWriteByte(HintMessage,-1);
	BfWriteString(HintMessage,message);
	EndMessage();
}

//FUNCTION FROM EXLUDE MESSAGES
stock GetNextSpaceCount(String:text[],CurIndex)
{
	new Count=0;
	new len = strlen(text);
	for(new i=CurIndex;i<len;i++)
	{
		if(text[i] == ' ')
			return Count;
		else
			Count++;
	}

	return Count;
}

//FUNCTION FROM EXLUDE MESSAGES
stock SendTopMessage(client,r,g,b,a,String:text[], any:...)
{
	new String:message[100]
	VFormat(message,191,text, 7)
	
	new Handle:kv = CreateKeyValues("Stuff", "title", message)
	KvSetColor(kv, "color", r, g, b, a)
	KvSetNum(kv, "level", 1)
	KvSetNum(kv, "time", 10)

	CreateDialog(client, kv, DialogType_Msg)

	CloseHandle(kv)

	return
}

//FUNCTION FROM TIMELEFT
Float:GetTimeLeft()
{
	new Float:fLimit = GetConVarFloat(g_hMpTimelimit);
	new Float:fElapsed = GetEngineTime() - g_fStartTime;
	
	return (fLimit*60.0) - fElapsed;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iReason = GetEventInt(event, "reason");
	if(iReason == 16)
	{
		g_fStartTime = GetEngineTime();		
	}	
}