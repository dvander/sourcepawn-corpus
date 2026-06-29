#pragma semicolon 1
#pragma newdecls required
/*

-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA512

War is bad.

This plugin was created during the War in Ukraine - 2022, instigated by the
President of the Russian Federation under what appears to be false pretenses.

The President of the Russian Federation has limited knowledge and access to
information for Russian Citizens.  The World can not see from within, and
Russian Citizens can not see outside.

For too long the Citizens of Russia have had their human rights violated
with no accountability for the executive council.

This has to stop.  The World is at risk.  This is our home.  It is our space
ship.  War has to stop.  The World is better off with Peace.

We have built this plugin to limit access to Source Engine servers
from users connecting from the Russian Federation in the hopes of spreading
the word.

Upon connection a player who's IP address is seen as being from a Russian
location will be locked out of game play and displayed a message calling for
an end to the war.  Chat, Comm, and in-game actions are blocked, and the
client will be banned after 30 seconds.

If you adapt, modify or distribute this plugin - please include this
message.



-----BEGIN PGP SIGNATURE-----

iQGzBAEBCgAdFiEEhK13k9C7KJZ6Vp1w44Pa6I4VCzgFAmIi2ScACgkQ44Pa6I4V
CzgWIgwAh71cw7l6XcSZqtwYawFgapAGVd8CfyFEeqHmCeoWkBvY3bBHh91bj7H/
W/IZP+bNY1rKSjtwoOCLR29T7ElZl/xcx67ulLkjM5zBM0LfOfobXsoSi2sZCB9S
KWjwatajbOv/C25DQ8aXx0Q+ETDqODp5nGC5xM1YggS6ZDkxtynpS4tw5BcDQzh2
zU1UXqCfLBF4YKgKiG8TBzxzeZpMa+9OR4iv0R5dQvgBT/tECDzbXFwh16/Im79z
N+XcGKIaPZvKNEOtycOqpz/EamrFpxb9s5+4w/Revk88rqlPlueKn6jIlRYTdmHg
LG1vK+8zJCxWQH/zclUyNKffhQaLiJCxFGZTdtOqLFqP7vGmLUuenh04PaKYrktn
CXB1SnS7IN5epu2/xdoWE6PDJcd2kq3jkXf9tjvoRe3bJzJJ63tLiy1TRA04tL5C
0ly4iu49luqGkh8kgXEBQjqbKXeX+vMjeRY9NxJPNm9a2lXy6vgxfb684NRm/2pb
0JiiT6BK
=8tto
-----END PGP SIGNATURE-----


*/

#include <geoip>
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <basecomm>
#include <sdktools_functions>


#define PLUGIN_NAME	"sm_nomorewar_ru"
#define PLUGIN_VERSION	"1.0"

#define HIDEHUD_WEAPONSELECTION         ( 1<<0 )        // Hide ammo count & weapon selection
#define HIDEHUD_FLASHLIGHT                      ( 1<<1 )
#define HIDEHUD_ALL                                     ( 1<<2 )
#define HIDEHUD_HEALTH                          ( 1<<3 )        // Hide health & armor / suit battery
#define HIDEHUD_PLAYERDEAD                      ( 1<<4 )        // Hide when local player's dead
#define HIDEHUD_NEEDSUIT                        ( 1<<5 )        // Hide when the local player doesn't have the HEV suit
#define HIDEHUD_MISCSTATUS                      ( 1<<6 )        // Hide miscellaneous status elements (trains, pickup history, death notices, etc)
#define HIDEHUD_CHAT                            ( 1<<7 )        // Hide all communication elements (saytext, voice icon, etc)
#define HIDEHUD_CROSSHAIR                       ( 1<<8 )        // Hide crosshairs
#define HIDEHUD_VEHICLE_CROSSHAIR       ( 1<<9 )        // Hide vehicle crosshair
#define HIDEHUD_INVEHICLE                       ( 1<<10 )
#define HIDEHUD_BONUS_PROGRESS          ( 1<<11 )       // Hide bonus progress display (for bonus map challenges)


#define FFADE_IN                        0x0001          // Just here so we don't pass 0 into the function
#define FFADE_OUT                       0x0002          // Fade out (not in)
#define FFADE_MODULATE          0x0004          // Modulate (don't blend)
#define FFADE_STAYOUT           0x0008          // ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE                     0x0010          // Purges all other fades, replacing them with this one

int maxTicks = 30;
char hudMessage2[] = "Russian Citizens are victims of their countries leadership.  No more War!";
char hudMessage2RU[] = "Вы жертва руководства вашей страны. Нет больше войны!";

char kickMessage[] = "Gain strength.  Stand up.  Build a better future.  STOP THE WAR IN UKRAINE!";
char chatMessage[] = "The War in Ukraine threatens all.  In solidarity with the people of Ukraine and mourning with the people of Russia this server is spreading the word. Stop the war!";
char chatMessageRU[] = "Война в Украине угрожает всем. Прекратить войну!";
char chatMessageUA[] = "Війна в Україні загрожує всім. Зупиніть війну!";

Handle hudSynchronizer2;


public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	version		= PLUGIN_VERSION,
	description	= "Limits access from Russia for the Ukraine War",
	author		= "Anonymous",
	url		= ""
}

ConVar cvarDebugIP;

int counter[MAXPLAYERS];
int debuggers[MAXPLAYERS];

public void OnPluginStart()
{
	CreateConVar("sm_nomorewar_ru_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);
	
	cvarDebugIP = CreateConVar("sm_nomorewar_ru_debugip", "", "");	// Set this convar to your IP address if you want to test from a specific IP.
	
	AutoExecConfig(true, "sm_nomorewar_ru");
	
	hudSynchronizer2 = CreateHudSynchronizer();	
	
}


public void OnClientPostAdminCheck(int client)
{
	if(!client || IsFakeClient(client))
		return;

	char debugIp[16];

	char ip[16], country[3];
	
	GetConVarString(cvarDebugIP, debugIp, sizeof(debugIp));
	
	GetClientIP(client, ip, sizeof(ip)); 

	if(StrEqual(ip, debugIp)) {
		debuggers[client]=1;
	} else {
		debuggers[client]=0;
	}

	counter[client]=0;

	if(GeoipCode2(ip, country) || debuggers[client]){
		if(debuggers[client]) {
			PrintToServer("DEBUG IP found for no more war");
			Format(country, sizeof(country), "RU");	
		}
		
		if(StrEqual(country, "RU")){
			doBanish(client);
		}
	} else {
		PrintToServer("geoIP lookup failed for %d", client);
	}
}


public void doBanish(int client)
{
	counter[client]++;
	
	BaseComm_SetClientMute(client, true);
	BaseComm_SetClientMute(client, true);
	
	PrintToChat(client, chatMessage);
	CreateTimer(1.0, showMessage, client, TIMER_REPEAT);
}

public Action showMessage(Handle timer, int client)
{
	counter[client]++;
	if(debuggers[client]){
		PrintToServer("Tick %d %d", counter[client], client);
	}
	
	if(counter[client]>=maxTicks){

		if(debuggers[client]){
			KickClient(client, "%s", "Your Country needs new, modern leadership. The world weeps for you.");
		} else {
			BanClient(client, 0, BANFLAG_AUTO, "RU: No More War", kickMessage);
		}
		counter[client]=0;
		debuggers[client]=0;
		KillTimer(timer);
		
		return(Plugin_Continue);
	}
	
	int rand = GetRandomInt(0,2);
	if(rand==0){
		PrintToChat(client, chatMessageUA);
	} else if(rand==1){
		PrintToChat(client, chatMessageRU);
	} else if(rand==2){
		PrintToChat(client, chatMessage);
	}
	
	SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	SetEntityRenderColor(client, 255, 0, 0,  50);
	
        SetEntProp(client, Prop_Send, "m_iHideHUD", HIDEHUD_WEAPONSELECTION | HIDEHUD_HEALTH | HIDEHUD_CROSSHAIR);
        
	ScreenFade(client, 0, FFADE_OUT | FFADE_STAYOUT | FFADE_PURGE);


        int msgColor[4];
 	msgColor[0] = 237;
	msgColor[1] = 87;
	msgColor[1] = 64;

	SetHudTextParams(-1.0, -1.0, 1.0, msgColor[0], msgColor[1], msgColor[2], msgColor[3]);
	if(rand==0){ 
		ShowSyncHudText(client, hudSynchronizer2, hudMessage2);
	} else if(rand==1){
		ShowSyncHudText(client, hudSynchronizer2, hudMessage2RU);	
	} else if(rand==2){
		ShowSyncHudText(client, hudSynchronizer2, hudMessage2RU);	
	}

	return(Plugin_Continue);	
}


public Action OnPlayerRunCmd(int client, int &buttons, int &impilse, float vel[3], float angles[3], int& weapon, int& subtype, int& cmdnum, int& tickcount, int& seed, int mouse[2])
{
	if(counter[client] >0){
		return(Plugin_Handled);
	}
	return(Plugin_Continue);
}

public Action OnClientCommand(int client, int args)
{
	if(counter[client] >0){
		return(Plugin_Handled);
	}
	return(Plugin_Continue);
}

public Action OnClientSayCommand(int client, const char[] command, const char[] args)
{
	if(counter[client]){
		return(Plugin_Handled);
	}
	return(Plugin_Continue);
}


stock bool ScreenFade(int client, int duration, int mode, int holdtime=-1, int r=0, int g=0, int b=0, int a=255, bool reliable=true)
{
        Handle userMessage = StartMessageOne("Fade", client, (reliable?USERMSG_RELIABLE:0));

        if (userMessage == INVALID_HANDLE) {
                return false;
        }

        if (GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available &&
                GetUserMessageType() == UM_Protobuf) {

                int color[4];
                color[0] = r;
                color[1] = g;
                color[2] = b;
                color[3] = a;

                PbSetInt(userMessage,   "duration",   duration);
                PbSetInt(userMessage,   "hold_time",  holdtime);
                PbSetInt(userMessage,   "flags",      mode);
                PbSetColor(userMessage, "clr",        color);
        }
        else {
                BfWriteShort(userMessage,       duration);      // Fade duration
                BfWriteShort(userMessage,       holdtime);      // Fade hold time
                BfWriteShort(userMessage,       mode);          // What to do
                BfWriteByte(userMessage,        r);                     // Color R
                BfWriteByte(userMessage,        g);                     // Color G
                BfWriteByte(userMessage,        b);                     // Color B
                BfWriteByte(userMessage,        a);                     // Color Alpha
        }
        EndMessage();

        return true;
}

