//linux_lover
#include <sourcemod>

public OnPluginStart()
{
	RegAdminCmd("sm_fakeitem", Command_FakeItem, ADMFLAG_SLAY);
}

public Action:Command_FakeItem(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "\x04[SM]\x01 Usage: sm_fakeitem <target> <weapon_name>");
		return Plugin_Handled;
	}
	
	new String:player[64];
	GetCmdArg(1, player, sizeof(player));	
	new String:weapon[64];
	GetCmdArg(2, weapon, sizeof(weapon));
	
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count
	new bool:tn_is_ml
 
	if ((target_count = ProcessTargetString(
			player,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(new i=0; i<target_count; i++)
	{
		FakeMessage(target_list[i], weapon);
	}
	
	return Plugin_Handled;
}

stock FakeMessage(client, String:weapon[64])
{
	new String:message[200];
	Format(message, sizeof(message), "\x03%N\x01 has found: \x06%s", client, weapon);
	
	SayText2(client, message);
	
	return;
}

stock SayText2(author_index , const String:message[] ) {
    new Handle:buffer = StartMessageAll("SayText2");
    if (buffer != INVALID_HANDLE) {
        BfWriteByte(buffer, author_index);
        BfWriteByte(buffer, true);
        BfWriteString(buffer, message);
        EndMessage();
    }
}