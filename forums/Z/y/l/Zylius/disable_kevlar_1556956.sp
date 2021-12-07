public OnPluginStart()
	 HookUserMessage(GetUserMessageId("ItemPickup"),UserMessageHook, true); 
public Action:UserMessageHook(UserMsg:MsgId, Handle:hBitBuffer, const iPlayers[], iNumPlayers, bool:bReliable, bool:bInit) 
{ 
	new String:itemname[24];
	BfReadString(hBitBuffer, itemname,sizeof(itemname));
	if(strcmp(itemname,"item_kevlar")==0 || strcmp(itemname,"item_assaultsuit")==0)
		return Plugin_Stop;
	return Plugin_Continue;
}  