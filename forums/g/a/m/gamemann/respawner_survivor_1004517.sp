#include <sourcemod>
#include <SDKtools>

#define Plugin_version "1"


Public Plugin:myinfo =
{
Name = "respawner_survivor",
Author = "christian (gamemann)",
Desciption = "when a survivor dies it gives them 1-2 minutes to respawn again",
Version = "Plugin_version,
URL = "",
}

Public OnPluginStart()
{
RegAdminCmd("sm_respawn_survivor", customCMD_Respawn_survivor, ADMFLAG_RESPAWN)
}

Public Action:customCMD_Respawn_survivor(cielent, Args)
	return plugin_handle;
}
new String:arg1[32], new String:arg2[32], new String:arg3[70]
new time
/* Get the first agument*/
GetCmdArg(1, arg1, timeof(45))
if(args>=2&&GetCmdArg(2,arg2,timeof(45))
{
time = stringtoint(arg2)
}

/* Finding a matching player*/
new target = findtarget(cielent, arg)
if(target == -1)
/* Findtarget) automatically replies with the 
* failure reason.
*/
	return Plugin_Handle;
}
respawn_survivor(target, time)
new string:name[max_spawn_time]

GetCielentName(target, name, timeof(spawn))
ReplyToCommand(cielent, "[SM} you have died but will spawn in (time)", name, time)
LoadAction(cielent, target, "\"%time\" time \"time%\" (time %t)", cielent, target. damage)
	return Plugin_handle;
}

////
//targets
////
native ProcessTargetString(const String:pattern[],
admin
targets[4+],
maxTargets[40],
filter_flags,
String:target_name[Arg2],
tn_maxlenth[100],
&bool:tn_is_ml);

//targets_1
{
if((Target_count = ProcessTargetString(
arg1,
cielent,
target_list,
MAXPLAYERS,
COMMAND_FILTER_DEAD, /* only allow dead players */
Target_name,
timeof(target_name),
tn_is_ml)) <=0)
}

///////
//let's load out config now :)
///////
AutoExecConfig(true, "l4d2_respawner_survivor");














