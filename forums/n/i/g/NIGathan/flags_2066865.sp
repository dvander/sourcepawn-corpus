#include <sourcemod>
#include <sdktools>
#include <string>

#define VERSION "0.004"

public Plugin:myinfo =
{
	name = "Niggy's Session Flags",
	author = "NIGathan",
	description = "Dynamically set users flags during the current session.",
	version = VERSION,
	url = "http://sandvich.justca.me/"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	CreateConVar("sm_flags_version", VERSION, "Niggy's Session Flags Version",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegAdminCmd("sm_flags", commandFlags, ADMFLAG_ROOT, "Changes clients admin flags on the fly.");
}

public Action:commandFlags(client, args)
{
	if (args < 2)
	{
		PrintToChat(client, "[SM] Usage: sm_flags <#userid|name> [+/add|-/remove|toggle] <flags> - The second arguement defaults to toggle if left empty.");
		return Plugin_Handled;
	}
	decl String:modes[10];
	new mode = 0;
	decl String:flags[42];
	decl String:target[65];
	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	GetCmdArg(1, target, sizeof(target));
	if (args > 2)
	{
		GetCmdArg(3, flags, sizeof(flags));
		GetCmdArg(2, modes, sizeof(modes));
		if (StrEqual(modes,"add",false) || StrEqual(modes,"+"))
			mode = 1;
		else if (StrEqual(modes,"remove",false) || StrEqual(modes,"rem",false) || StrEqual(modes,"-"))
			mode = 2;
	}
	else GetCmdArg(2, flags, sizeof(flags));
	
	if ((target_count = ProcessTargetString(
			target,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_BOTS,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	formatFlags(flags);
	
	for (new i = 0; i < target_count; i++)
	{
		for (new j = 0; j < strlen(flags); j++)
			setFlag(target_list[i],client,flags[j],mode);
	}
	
	if (!StrEqual(flags,""))
	{
		if (tn_is_ml)
		{
			if (!mode) ShowActivity2(client, "[SM] ", "Toggled \"%s\" flags on %t", flags, target_name);
			else if (mode == 1) ShowActivity2(client, "[SM] ", "Set \"%s\" flags on %t", flags, target_name);
			else if (mode == 2) ShowActivity2(client, "[SM] ", "Removed \"%s\" flags from %t", flags, target_name);
		}
		else
		{
			if (!mode) ShowActivity2(client, "[SM] ", "Toggled \"%s\" flags on %s", flags, target_name);
			else if (mode == 1) ShowActivity2(client, "[SM] ", "Set \"%s\" flags on %s", flags, target_name);
			else if (mode == 2) ShowActivity2(client, "[SM] ", "Removed \"%s\" flags from %s", flags, target_name);
		}
	}
	return Plugin_Handled;
}

formatFlags(String:flags[42])
{
	for (new i = 0; i < strlen(flags); i++)
	{
		switch ((flags[i] = CharToLower(flags[i])))
		{
			case 'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'z':
			{
				continue;
			}
			default:
			{
				new String:poop[1]; // ReplaceString doesn't seem to like a non-array string.
				poop[0] = flags[i];
				ReplaceStringEx(flags, sizeof(flags), poop, "", 1, 0);
				i--;
			}
		}
	}
}

setFlag(client, from, String:flag, mode)
{
	if (!mode)
	{
		switch (flag)
		{
			case 'a':
			{
				if (GetUserFlagBits(client) & ADMFLAG_RESERVATION) remFlag(client,from,flag);
				else addFlag(client,from,flag);
			}
			case 'b':
			{
				if (GetUserFlagBits(client) & ADMFLAG_GENERIC) remFlag(client,from,flag);
				else addFlag(client,from,flag);
			}
			case 'c':
			{
				if (GetUserFlagBits(client) & ADMFLAG_KICK) remFlag(client,from,flag);
				else addFlag(client,from,flag);
			}
			case 'd':
			{
				if (GetUserFlagBits(client) & ADMFLAG_BAN) remFlag(client,from,flag);
				else addFlag(client,from,flag);
			}
			case 'e':
			{
				if (GetUserFlagBits(client) & ADMFLAG_UNBAN) remFlag(client,from,flag);
				else addFlag(client,from,flag);
			}
			case 'f':
			{
				if (GetUserFlagBits(client) & ADMFLAG_SLAY) remFlag(client,from,flag);
				else addFlag(client,from,flag);
			}
			case 'g':
			{
				if (GetUserFlagBits(client) & ADMFLAG_CHANGEMAP) remFlag(client,from,flag);
				else addFlag(client,from,flag);
			}
			case 'h':
			{
				if (GetUserFlagBits(client) & ADMFLAG_CONVARS) remFlag(client,from,flag);
				else addFlag(client,from,flag);
			}
			case 'i':
			{
				if (GetUserFlagBits(client) & ADMFLAG_CONFIG) remFlag(client,from,flag);
				else addFlag(client,from,flag);
			}
			case 'j':
			{
				if (GetUserFlagBits(client) & ADMFLAG_CHAT) remFlag(client,from,flag);
				else addFlag(client,from,flag);
			}
			case 'k':
			{
				if (GetUserFlagBits(client) & ADMFLAG_VOTE) remFlag(client,from,flag);
				else addFlag(client,from,flag);
			}
			case 'l':
			{
				if (GetUserFlagBits(client) & ADMFLAG_PASSWORD) remFlag(client,from,flag);
				else addFlag(client,from,flag);
			}
			case 'm':
			{
				if (GetUserFlagBits(client) & ADMFLAG_RCON) remFlag(client,from,flag);
				else addFlag(client,from,flag);
			}
			case 'n':
			{
				if (GetUserFlagBits(client) & ADMFLAG_CHEATS) remFlag(client,from,flag);
				else addFlag(client,from,flag);
			}
			case 'o':
			{
				if (GetUserFlagBits(client) & ADMFLAG_CUSTOM1) remFlag(client,from,flag);
				else addFlag(client,from,flag);
			}
			case 'p':
			{
				if (GetUserFlagBits(client) & ADMFLAG_CUSTOM2) remFlag(client,from,flag);
				else addFlag(client,from,flag);
			}
			case 'q':
			{
				if (GetUserFlagBits(client) & ADMFLAG_CUSTOM3) remFlag(client,from,flag);
				else addFlag(client,from,flag);
			}
			case 'r':
			{
				if (GetUserFlagBits(client) & ADMFLAG_CUSTOM4) remFlag(client,from,flag);
				else addFlag(client,from,flag);
			}
			case 's':
			{
				if (GetUserFlagBits(client) & ADMFLAG_CUSTOM5) remFlag(client,from,flag);
				else addFlag(client,from,flag);
			}
			case 't':
			{
				if (GetUserFlagBits(client) & ADMFLAG_CUSTOM6) remFlag(client,from,flag);
				else addFlag(client,from,flag);
			}
			case 'z':
			{
				if (GetUserFlagBits(client) & ADMFLAG_ROOT) remFlag(client,from,flag);
				else addFlag(client,from,flag);
			}
		}
	}
	else if (mode == 1)
		addFlag(client,from,flag);
	else if (mode == 2)
		remFlag(client,from,flag);
}

addFlag(client, from, String:flag)
{
	switch (flag)
	{
		case 'a':
		{
			AddUserFlags(client,Admin_Reservation);
		}
		case 'b':
		{
			AddUserFlags(client,Admin_Generic);
		}
		case 'c':
		{
			AddUserFlags(client,Admin_Kick);
		}
		case 'd':
		{
			AddUserFlags(client,Admin_Ban);
		}
		case 'e':
		{
			AddUserFlags(client,Admin_Unban);
		}
		case 'f':
		{
			AddUserFlags(client,Admin_Slay);
		}
		case 'g':
		{
			AddUserFlags(client,Admin_Changemap);
		}
		case 'h':
		{
			AddUserFlags(client,Admin_Convars);
		}
		case 'i':
		{
			AddUserFlags(client,Admin_Config);
		}
		case 'j':
		{
			AddUserFlags(client,Admin_Chat);
		}
		case 'k':
		{
			AddUserFlags(client,Admin_Vote);
		}
		case 'l':
		{
			AddUserFlags(client,Admin_Password);
		}
		case 'm':
		{
			AddUserFlags(client,Admin_RCON);
		}
		case 'n':
		{
			AddUserFlags(client,Admin_Cheats);
		}
		case 'o':
		{
			AddUserFlags(client,Admin_Custom1);
		}
		case 'p':
		{
			AddUserFlags(client,Admin_Custom2);
		}
		case 'q':
		{
			AddUserFlags(client,Admin_Custom3);
		}
		case 'r':
		{
			AddUserFlags(client,Admin_Custom4);
		}
		case 's':
		{
			AddUserFlags(client,Admin_Custom5);
		}
		case 't':
		{
			AddUserFlags(client,Admin_Custom6);
		}
		case 'z':
		{
			AddUserFlags(client,Admin_Root);
		}
		default:
		{
			return;
		}
	}
	LogAction(from,client, "\"%L\" set +%s on \"%L\".", from, flag, client);
}

remFlag(client, from, String:flag)
{
	switch (flag)
	{
		case 'a':
		{
			RemoveUserFlags(client,Admin_Reservation);
		}
		case 'b':
		{
			RemoveUserFlags(client,Admin_Generic);
		}
		case 'c':
		{
			RemoveUserFlags(client,Admin_Kick);
		}
		case 'd':
		{
			RemoveUserFlags(client,Admin_Ban);
		}
		case 'e':
		{
			RemoveUserFlags(client,Admin_Unban);
		}
		case 'f':
		{
			RemoveUserFlags(client,Admin_Slay);
		}
		case 'g':
		{
			RemoveUserFlags(client,Admin_Changemap);
		}
		case 'h':
		{
			RemoveUserFlags(client,Admin_Convars);
		}
		case 'i':
		{
			RemoveUserFlags(client,Admin_Config);
		}
		case 'j':
		{
			RemoveUserFlags(client,Admin_Chat);
		}
		case 'k':
		{
			RemoveUserFlags(client,Admin_Vote);
		}
		case 'l':
		{
			RemoveUserFlags(client,Admin_Password);
		}
		case 'm':
		{
			RemoveUserFlags(client,Admin_RCON);
		}
		case 'n':
		{
			RemoveUserFlags(client,Admin_Cheats);
		}
		case 'o':
		{
			RemoveUserFlags(client,Admin_Custom1);
		}
		case 'p':
		{
			RemoveUserFlags(client,Admin_Custom2);
		}
		case 'q':
		{
			RemoveUserFlags(client,Admin_Custom3);
		}
		case 'r':
		{
			RemoveUserFlags(client,Admin_Custom4);
		}
		case 's':
		{
			RemoveUserFlags(client,Admin_Custom5);
		}
		case 't':
		{
			RemoveUserFlags(client,Admin_Custom6);
		}
		case 'z':
		{
			RemoveUserFlags(client,Admin_Root);
		}
		default:
		{
			return;
		}
	}
	LogAction(from,client, "\"%L\" set -%s on \"%L\".", from, flag, client);
}

