#include <sourcemod>
#include <sdktools>
#define PLUGIN_VERSION "1.0.2"

new Handle:v_DefaultPower = INVALID_HANDLE;
new Handle:v_DefaultAngle = INVALID_HANDLE;
new Handle:v_Log = INVALID_HANDLE;
new Handle:v_AdminOnly = INVALID_HANDLE;
new Handle:v_Enable = INVALID_HANDLE;


public Plugin:myinfo =
{
	name = "[ANY] Ninja Leap",
	author = "DarthNinja",
	description = "Leap through the air!",
	version = PLUGIN_VERSION,
	url = "DarthNinja.com"
};

public OnPluginStart()
{
	CreateConVar("sm_ninjaleap_version",PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	v_Enable = CreateConVar("sm_ninjaleap_enable", "1", "Enable/Disable the plugin", 0, true, 0.0, true, 1.0);
	v_DefaultPower = CreateConVar("sm_ninjaleap_power", "1000", "The default force/power to throw players for");
	v_DefaultAngle = CreateConVar("sm_ninjaleap_angle", "-30", "The angle to launch players at.  -90 is straight up.");
	v_Log = CreateConVar("sm_ninjaleap_log", "0", "Set to 1 to make the plugin keep a log of leapers", 0, true, 0.0, true, 1.0);
	v_AdminOnly = CreateConVar("sm_ninjaleap_admin", "0", "Set to 1 to make the plugin admin-only", 0, true, 0.0, true, 1.0);
	
	RegConsoleCmd("leap", NinjaLeap, "Leap like a Ninja!");
	RegConsoleCmd("ninjaleap", NinjaLeap, "Leap like a Ninja!");
	
	LoadTranslations("common.phrases");
}


public Action:NinjaLeap(client, args)
{
	if (!GetConVarBool(v_Enable))
	{
		ReplyToCommand(client,"[SM] Sorry: NinjaLeap is currently disabled!");
		return Plugin_Handled;
	}
	if (GetConVarBool(v_AdminOnly) && !CheckCommandAccess(client, "sm_ninjaleap_override", ADMFLAG_SLAY))
		return Plugin_Handled;
	if (args < 0 || args > 2)
	{
		ReplyToCommand(client,"[SM] Usage: ninjaleap [Power] [Angle]");
		return Plugin_Handled;
	}
	
	//Defaut power cvar value
	new Float:f_Power = GetConVarFloat(v_DefaultPower);
	if (args >= 1) // Player wants a custom force
	{
		decl String:Power[32];
		GetCmdArg(1, Power, sizeof(Power));
		f_Power = StringToFloat(Power);
	}
	
	//Defaut angle cvar value
	new Float:f_Angle = GetConVarFloat(v_DefaultAngle);
	if (args == 2) // Player wants a custom angle
	{
		decl String:Angle[32];
		GetCmdArg(2, Angle, sizeof(Angle));
		f_Angle = StringToFloat(Angle);
	}
	
	if (GetConVarBool(v_Log))
	{
		LogAction(client, client, "%L Flew through the air like a Ninja!", client);
	}
	
	new Float:ClientEyeAngle[3];
	new Float:ClientAbsOrigin[3];
	new Float:Velocity[3];
	
	GetClientAbsOrigin(client, ClientAbsOrigin);	// Client location
	GetClientEyeAngles(client, ClientEyeAngle);	// Client view direction
	
	new Float:EyeAngleZero = ClientEyeAngle[0];	//Save the angle
	ClientEyeAngle[0] = f_Angle;	//change the angle so players fly in a curve instead of where they're looking
	GetAngleVectors(ClientEyeAngle, Velocity, NULL_VECTOR, NULL_VECTOR);	//Work out the angle to throw
	// Set the power for the throw
	ScaleVector(Velocity, f_Power);
	ClientEyeAngle[0] = EyeAngleZero;	//Restore the value so the client's view wont be messed with
	
	TeleportEntity(client, ClientAbsOrigin, ClientEyeAngle, Velocity); //Toss 'em
	
	return Plugin_Handled;
}