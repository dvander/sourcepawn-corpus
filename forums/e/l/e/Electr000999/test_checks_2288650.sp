#include <sourcemod>

#pragma	semicolon 1
#pragma newdecls required

enum TestType
{
	TYPE_ONE = 1,	TYPE_TWO,		TYPE_THREE
}

public void OnPluginStart()
{
	RegConsoleCmd ( "sm_test"					, CmdTest, "");
}

public Action CmdTest(int client, int args)
{
	int iVar = 3;
	
	// WORKS CORRECT
	if(iVar != 3)
	{
		PrintToChatAll("[test 1] %i != 3", iVar);
	}
	else
	{
		PrintToChatAll("[test 1] %i == 3", iVar);
	}
	
	// WORKS CORRECT
	if(!(iVar == 2 || iVar == 3))
	{
		PrintToChatAll("[test 2] %i != 2 or 3", iVar);
	}
	
	// OLD variant view_as work fine
	if(!(iVar == _:TYPE_TWO || iVar == _:TYPE_THREE))
	{
		PrintToChatAll("[test 3] %i != %i or %i", iVar, TYPE_TWO, TYPE_THREE);
	}
	
	// BROKEN
	if(!(iVar == view_as<int>TYPE_TWO || iVar == view_as<int>TYPE_THREE))
	{
		PrintToChatAll("[test 4] %i != %i or %i - !BUG!", iVar, TYPE_TWO, TYPE_THREE);
	}
	
	// WORKS CORRECT if i am place check in ()
	if(!((iVar == view_as<int>TYPE_TWO) || (iVar == view_as<int>TYPE_THREE)))
	{
		PrintToChatAll("[test 5] %i != %i or %i", iVar, TYPE_TWO, TYPE_THREE);
	}
}
