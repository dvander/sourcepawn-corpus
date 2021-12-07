#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

public OnPluginStart()
{
	RegAdminCmd("sm_tag", Rename, ADMFLAG_GENERIC);
}

public Action:Rename(client, args)
{
	if(args < 2)
		ReplyToCommand(client, "[SM] Usage: sm_tag <partial name> <tag>");
	else
	{
		decl String:target[64];
		GetCmdArg(1, target, sizeof(target));
		decl String:tag[64];
		GetCmdArg(2, tag, sizeof(tag));
		new targetindex = FindTarget(client, target);
		if(targetindex > 0)
		{
			decl String:clientName[64];
			GetClientName(targetindex, clientName, sizeof(clientName));
			ShowActivity2(client, "[SM] ", "%N added %s tag to %N.", client, tag, targetindex);
			StrCat(tag, sizeof(clientName), clientName);
			CS_SetClientName(targetindex, tag);
		}
	}
}

stock CS_SetClientName(client, const String:name[], bool:silent=false)
{
    decl String:oldname[MAX_NAME_LENGTH];
    GetClientName(client, oldname, sizeof(oldname));

    SetClientInfo(client, "name", name);
    SetEntPropString(client, Prop_Data, "m_szNetname", name);

    new Handle:event = CreateEvent("player_changename");

    if (event != INVALID_HANDLE)
    {
        SetEventInt(event, "userid", GetClientUserId(client));
        SetEventString(event, "oldname", oldname);
        SetEventString(event, "newname", name);
        FireEvent(event);
    }

    if (silent)
        return;
    
    new Handle:msg = StartMessageAll("SayText2");

    if (msg != INVALID_HANDLE)
    {
        BfWriteByte(msg, client);
        BfWriteByte(msg, true);
        BfWriteString(msg, "Cstrike_Name_Change");
        BfWriteString(msg, oldname);
        BfWriteString(msg, name);
        EndMessage();
    }
}