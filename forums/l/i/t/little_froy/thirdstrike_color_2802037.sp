#define PLUGIN_VERSION  "1.1"
#define PLUGIN_NAME     "Thirdstrike Color"

#pragma tabsize 0
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = "little_froy",
	description = "game play",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=342332"
};

GlobalForward Forward_OnSetColor;
GlobalForward Forward_OnResetColor;

ConVar C_color;

int O_color[3];

bool Added[MAXPLAYERS+1];

bool is_survivor_on_thirdstrike(int client)
{
	return !!GetEntProp(client, Prop_Send, "m_bIsOnThirdStrike");
}

void set_color(int client)
{
    if(!Added[client])
    {
        Added[client] = true;
        SetEntityRenderColor(client, O_color[0], O_color[1], O_color[2], 255);
        Call_StartForward(Forward_OnSetColor);
        Call_PushCell(client);
        Call_Finish();
    }
}

void reset_color(int client)
{
    if(Added[client])
    {
        Added[client] = false;
        SetEntityRenderColor(client, 255, 255, 255, 255);
        Call_StartForward(Forward_OnResetColor);
        Call_PushCell(client);
        Call_Finish();
    }
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    if(GetClientTeam(client) == 2 && IsPlayerAlive(client) && is_survivor_on_thirdstrike(client))
    {
        set_color(client);
    }
    else
    {
        reset_color(client);
    }
}

public void OnClientDisconnect_Post(int client)
{
	Added[client] = false;
}

void reset_all()
{
    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client))
        {
            reset_color(client);
        }
        Added[client] = false;
    }
}

void event_round_start(Event event, const char[] name, bool dontBroadcast)
{
    reset_all();
}

void get_color()
{
    static char cvar_colors[13];
    C_color.GetString(cvar_colors, sizeof(cvar_colors));
	static char colors_get[3][4];
	ExplodeString(cvar_colors, " ", colors_get, 3, 4);
    for(int i = 0; i < 3; i++)
    {
        O_color[i] = StringToInt(colors_get[i]);
        if(O_color[i] < 0)
        {
            O_color[i] = 0;
        }
        else if(O_color[i] > 255)
        {
            O_color[i] = 255;
        }
    }
}

void get_cvars()
{
    get_color();

    reset_all();
}

void convar_changed(ConVar convar, const char[] oldValue, const char[] newValue)
{
	get_cvars();
}

public void OnConfigsExecuted()
{
	get_cvars();
}

any native_ThirdstrikeColor_HasSetColor(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	if(client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_INDEX, "client index %d is out of bound", client);
	}
	return Added[client];
}

public APLRes AskPluginLoad2(Handle plugin, bool late, char[] error, int err_max)
{
    Forward_OnSetColor = new GlobalForward("ThirdstrikeColor_OnSetColor", ET_Ignore, Param_Cell);
    Forward_OnResetColor = new GlobalForward("ThirdstrikeColor_OnResetColor", ET_Ignore, Param_Cell);
    CreateNative("ThirdstrikeColor_HasSetColor", native_ThirdstrikeColor_HasSetColor);
    RegPluginLibrary("thirdstrike_color");
    return APLRes_Success;
}

public void OnPluginStart()
{
    HookEvent("round_start", event_round_start);

    C_color = CreateConVar("thirdstrike_color_value", "0 0 0", "color of thirdstrike, split up with space");

    CreateConVar("thirdstrike_color_version", PLUGIN_VERSION, "version of " ... PLUGIN_NAME, FCVAR_NOTIFY | FCVAR_DONTRECORD);

    C_color.AddChangeHook(convar_changed);

    AutoExecConfig(true, "thirdstrike_color");
}