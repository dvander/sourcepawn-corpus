{\rtf1\ansi\ansicpg1252\deff0\deflang2057{\fonttbl{\f0\fswiss\fcharset0 Arial;}}
{\*\generator Msftedit 5.41.21.2508;}\viewkind4\uc1\pard\f0\fs20 #pragma semicolon 1\par
\par
#include <sourcemod>\par
\par
\par
\par
public OnPluginStart()\par
\{\par
RegAdminCmd("sm_sethealth", Command_SetHealth, ADMFLAG_SLAY, "sm_sethealth <#userid|name> <amount>");\par
\}\par
\par
public Action:Command_SetHealth(client, args)\par
\{\par
decl String:target[32], String:mod[32], String:health[10];\par
new nHealth;\par
\par
GetGameFolderName(mod, sizeof(mod));\par
\par
if (args < 2)\par
\{\par
ReplyToCommand(client, "[SM] Usage: sm_sethealth <#userid|name> <amount>");\par
return Plugin_Handled;\par
\}\par
\par
GetCmdArg(1, target, sizeof(target));\par
GetCmdArg(2, health, sizeof(health));\par
nHealth = StringToInt(health);\par
\par
\par
if (nHealth < 0) \{\par
ReplyToCommand(client, "[SM] Health must be greater then zero.");\par
return Plugin_Handled;\par
\}\par
\par
decl String:target_name[MAX_TARGET_LENGTH];\par
new target_list[MAXPLAYERS], target_count, bool:tn_is_ml;\par
\par
if ((target_count = ProcessTargetString(\par
target,\par
client,\par
target_list,\par
MAXPLAYERS,\par
COMMAND_FILTER_ALIVE,\par
target_name,\par
sizeof(target_name),\par
tn_is_ml)) <= 0)\par
\{\par
ReplyToTargetError(client, target_count);\par
return Plugin_Handled;\par
\}\par
\par
for (new i = 0; i < target_count; i++)\par
\{\par
if(nHealth > 100)\par
  \{\par
  SetEntProp(target_list[i], Prop_Data, "m_iMaxHealth", nHealth);\par
  \}\par
SetEntityHealth(target_list[i], nHealth);\par
\}\par
\par
ShowActivity2(client, "[SM] ", "Set health of %s to %d", target_name, nHealth);\par
ShowHudText(client, -1, "Set health of %s to %d", target_name, nHealth );\par
return Plugin_Handled;\par
\par
\}\par
}
 