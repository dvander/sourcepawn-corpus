
#pragma semicolon 1
#include <sourcemod>
#include <memoryhack>

	
public Plugin:myinfo = 
{
	name = "Memoey Hack Demo - CSS",
	author = "ben",
	description = "Memoey Hack Demo - CSS",
	version = "1.0.0.0",
	url = "http://www.zombiex2.net/"
};


#define PATCH_BLOCK_ROUND_END_SIZE		3

new Handle:memhndl = INVALID_HANDLE;
new Handle:memhndl2 = INVALID_HANDLE;
new Handle:memhndl3 = INVALID_HANDLE;

new iSave_BlockRoundEnd[PATCH_BLOCK_ROUND_END_SIZE];
new iPatch_BlockRoundEnd[PATCH_BLOCK_ROUND_END_SIZE];
new bool:did_save_BlockRoundEnd = false;

public OnPluginStart()
{
	new Handle:hConfig = LoadGameConfigFile("memoryhack");
	if(hConfig == INVALID_HANDLE)
	{
		SetFailState("Load memoryhack Config Fail");
	}
	PrintToServer("--------------------------");
	
	
	/* Block Round End */
	memhndl = CreateMemHackFromConf(hConfig,"BlockRoundEnd","",MEM_TYPE_CODE);
	if(memhndl != INVALID_HANDLE)
	{
		PrintToServer("Getting BlockRoundEnd Success");
		if(MH_ReadPatchBytes(hConfig,"BlockRoundEnd",iPatch_BlockRoundEnd,PATCH_BLOCK_ROUND_END_SIZE))
		{
			PrintToServer("Getting BlockRoundEnd Patch Bytes Success");
			RegServerCmd("sv_noroundend",NoRoundEndCmd,"No Round End in CSS");
		} else {
			PrintToServer("Getting BlockRoundEnd Patch Bytes Fail");
		}
	} else {
		PrintToServer("[*]Getting BlockRoundEnd Fail");
	}
	
	
	/* Change Description Name */
	/* Original Name "Counter-Strike: Source" Length 22 */
	memhndl2 = CreateMemHackFromConf(hConfig,"DescriptionName","",MEM_TYPE_RODATA);
	if(memhndl2 != INVALID_HANDLE)
	{
		PrintToServer("--------------------------");
		PrintToServer("Getting DescriptionName Success");
		new String:original_name[22];
		MH_Read_String(memhndl2,original_name,22);
		PrintToServer("Orginal Description Name: \"%s\"",original_name);
		new String:patch_name[] = "Memory Hack CSS";
		MH_Patch_String(memhndl2,patch_name,sizeof(patch_name),true);
		PrintToServer("Patched Description Name");
		new String:new_name[22];
		MH_Read_String(memhndl2,new_name,22);
		PrintToServer("New Description Name: \"%s\"",new_name);
	} else {
		PrintToServer("[*]Getting DescriptionName Fail");
	}
	
	
	/* Change CT Touch Hostage Money, original is $150 */
	/* Target: Change "96" to another
	-> windows (offset = 19)
223453C0	A1 84 7A 57 22                          mov     eax, dword_22577A84
			8B 4C 24 04                             mov     ecx, [esp+arg_0]
			83 80 5C 02 00 00 64                    add     dword ptr [eax+25Ch], 64h
			6A 01                                   push    1
223453D2	68 96 00 00 00                          push    96h
	
	"96" = 223453D2 + 1 = 223453D3, windows offset = 223453D3 - 223453C0 = 13, convert to decimal = 19
	
	-> linux (offset = 976)
00A48DC0 	_ZN8CHostage10HostageUseEP11CBaseEntityS1_8USE_TYPEf
			C6 83 A0 07 00 00 01                    mov     byte ptr [ebx+7A0h], 1
			8B 15 44 B9 C9 00                       mov     edx, ds:g_pGameRules
			B9 01 00 00 00                          mov     ecx, 1
00A4918F	BE 96 00 00 00                          mov     esi, 96h
			83 82 58 02 00 00 64                    add     dword ptr [edx+258h], 64h
		
	"96" = 00A4918F +1 = 00A49190,  linux offset = 00A49190 - 00A48DC0 = 3D0, convert to decimal = 976
	*/
	
	memhndl3 = CreateMemHackFromConf(hConfig,"TouchHostageMoney","TouchHostageMoney",MEM_TYPE_CODE);
	if(memhndl3 != INVALID_HANDLE)
	{
		PrintToServer("--------------------------");
		PrintToServer("Getting TouchHostageMoney Success");
		new original_money[1];
		MH_Read_Dwords(memhndl3,original_money,1);
		PrintToServer("Orginal TouchHostageMoney: \"%d\"",original_money[0]);
		MH_Patch_Dwords(memhndl3,{777},1);
		PrintToServer("Patched TouchHostageMoney");
		new new_money[1];
		MH_Read_Dwords(memhndl3,new_money,1);
		PrintToServer("New TouchHostageMoney: \"%d\"",new_money[0]);
	} else {
		PrintToServer("[*]Getting TouchHostageMoney Fail");
	}
	
	PrintToServer("--------------------------");
	CloseHandle(hConfig);
}



public OnPluginEnd()
{
	UnPatch_RoundEnd();
	if(memhndl != INVALID_HANDLE)
		CloseHandle(memhndl);
	if(memhndl2 != INVALID_HANDLE)
		CloseHandle(memhndl2);
	if(memhndl3 != INVALID_HANDLE)
		CloseHandle(memhndl3);
}

public Action:NoRoundEndCmd(args)
{
	if(args != 1)
	{
		PrintToServer("sv_noroundend value is %d", (did_save_BlockRoundEnd) ? 1 : 0);
		return Plugin_Handled;
	}
	
	new String:buff[8];
	GetCmdArg(1,buff,sizeof(buff));
	new value = StringToInt(buff);
	
	if(value == 1)
	{
		Patch_RoundEnd();
	} else {
		UnPatch_RoundEnd();
	}
	return Plugin_Handled;
}

public Patch_RoundEnd()
{
	if(!did_save_BlockRoundEnd)
	{
		MH_Read_UnsignedBytes(memhndl,iSave_BlockRoundEnd,PATCH_BLOCK_ROUND_END_SIZE);
		MH_Patch_UnsignedBytes(memhndl,iPatch_BlockRoundEnd,PATCH_BLOCK_ROUND_END_SIZE);
		PrintToServer("BlockRoundEnd saved & patched");
		did_save_BlockRoundEnd = true;
	}
}

public UnPatch_RoundEnd()
{
	if(did_save_BlockRoundEnd)
	{
		MH_Patch_UnsignedBytes(memhndl,iSave_BlockRoundEnd,PATCH_BLOCK_ROUND_END_SIZE);
		PrintToServer("BlockRoundEnd reveted");
		did_save_BlockRoundEnd = false;
	}
}
