#include <sourcemod>

public OnPluginStart()
{
	HookUserMessage( GetUserMessageId( "VGUIMenu" ), OnMsgVGUIMenu );
}

public Action:OnMsgVGUIMenu( UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init )
{
	decl String:buffer1[256], String:buffer2[256], String:path[256];
	BuildPath(Path_SM, path, sizeof(path), "logs/vguipanels.log");
	BfReadString( bf, buffer1, sizeof(buffer1) );
	LogToFile(path, "VGui Menu Received" );
	LogToFile(path, "Panel Name:  \"%s\"", buffer1 );
	LogToFile(path, "Hidden: %s", BfReadByte( bf ) == 0 ? "true" : "false" );
	
	new key_count = BfReadByte( bf );
	if( key_count == 0 )
		return;
	
	LogToFile(path, "Keys:" );
	for( new i = 0; i < key_count; ++i )
	{
		BfReadString(bf, buffer1, sizeof(buffer1));
		BfReadString(bf, buffer2, sizeof(buffer2));
		LogToFile(path, "	\"%s\"  =>  \"%s\"", buffer1, buffer2 );
	}
}