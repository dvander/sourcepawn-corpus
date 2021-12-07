#pragma semicolon 1
#include <sdktools>
#include <sourcemod>
#include <system>
#include <profiler>

#define RC4KEY	"[™]ÈvèntScRÏPt {★☆}ck"
public Plugin:myinfo = 
{
    name = "system extension simple",
    author = "ben",
    description = "system extension simple",
    version = "1.0",
    url = "http://www.sourcemod.net"
};
public OnPluginStart()
{
	RegConsoleCmd("sec1", sec1_command); // create process
	RegConsoleCmd("sec2", sec2_command); // rc4 simple
	RegConsoleCmd("sec3", sec3_command); // md5 simple
	RegConsoleCmd("sec4", sec4_command); // md5 ASM simple
	RegConsoleCmd("sec5", sec5_command); // RandomString simple
	RegConsoleCmd("sec6", sec6_command); // md5 benchmark, run 1,000,000 times ~8.0
	RegConsoleCmd("sec7", sec7_command); // md5 benchmark, use ASM run 1,000,000 times ~6.1
}
public Action:sec1_command(client,args)
{
	RunSystemCommand("c:\\windows\\notepad.exe",PRI_REALTIME,SW_SHOWMAXIMIZED);
	return Plugin_Handled;
}
public Action:sec2_command(client,args)
{
	decl String:output[1024];
	decl String:output2[1024];
	Rc4Encryption("SÒUrCeMÒÐ GĂÿ ®",RC4KEY,output,sizeof(output));
	PrintToServer("%s",output);
	Rc4Dencryption(output,RC4KEY,output2,sizeof(output2));
	PrintToChatAll("%s",output2);
	PrintToServer("%s",output2);
	return Plugin_Handled;
}
public Action:sec3_command(client,args)
{
	PrintToServer("MD5 test");
	md5test(false);
	return Plugin_Handled;
}
public Action:sec4_command(client,args)
{
	PrintToServer("MD5 ASM test");
	md5test(true);
	return Plugin_Handled;
}
public Action:sec5_command(client,args)
{
	decl String:output[512];
	GetRandomString(output,sizeof(output),64,true,true,true,true);
	PrintToServer("%s",output);
	return Plugin_Handled;
}
public Action:sec6_command(client,args)
{
	new Handle:benchmark = CreateProfiler();
	StartProfiling(benchmark);
	for(new i=0;i<1000000;i++)
		I_am_very_long(false);
	StopProfiling(benchmark);
	PrintToServer("MD5 time: %f",GetProfilerTime(benchmark));
	CloseHandle(benchmark);
	return Plugin_Handled;
}
public Action:sec7_command(client,args)
{
	new Handle:benchmark = CreateProfiler();
	StartProfiling(benchmark);
	for(new i=0;i<1000000;i++)
		I_am_very_long(true);
	StopProfiling(benchmark);
	PrintToServer("MD5 ASM time: %f",GetProfilerTime(benchmark));
	CloseHandle(benchmark);
	return Plugin_Handled;
}
stock md5test(bool:useasm)
{
	//http://www.md5-creator.com/
	
	decl String:output[512];
	
	Md5Encryption("123",output,sizeof(output),false,useasm);
	PrintToServer("%s",output);
	PrintToServer("202CB962AC59075B964B07152D234B70");
	
	Md5Encryption("1234567890",output,sizeof(output),useasm);
	PrintToServer("%s",output);
	PrintToServer("e807f1fcf82d132f9bb018ca6738a19f");
	
	Md5Encryption("1234567890abcdefghijklmnopqrstuvwxyz~!@#$%^&*()_+",output,sizeof(output),useasm);
	PrintToServer("%s",output);
	PrintToServer("2c9cc9fbfd37e67ff42bf26bf73e2ca5");
	
	Md5Encryption("SÒUrCeMÒÐ GĂÿ ®",output,sizeof(output),false,useasm);
	PrintToServer("%s",output);
	PrintToServer("AC6D03FAE457138FA73D815363793A0F");
	
}
stock I_am_very_long(bool:useasm)
{
	decl String:output[64];
	Md5Encryption("As a special exception, AlliedModders LLC gives you permission to link the code of this program (as well as its derivative works) to Half-Life 2, the Source Engine, the SourcePawn JIT, and any Game MODs that run on software by the Valve Corporation.  You must obey the GNU General Public License in all respects for all other code used.  Additionally, AlliedModders LLC grants this exception to all derivative works.  AlliedModders LLC defines further exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007)",output,sizeof(output),true,useasm);
}