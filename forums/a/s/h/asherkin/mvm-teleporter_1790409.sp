#pragma semicolon 1
#include <sourcemod>

/* myinfo */

enum
{
	OpCode_1_TWOBYTE = 0x0F,
	OpCode_1_JZ = 0x74,
	OpCode_1_NOP = 0x90,
	OpCode_1_JMP = 0xE9,
}

enum
{
	OpCode_2_JNZ = 0x85
}

enum Platform
{
	Platform_Invalid,
	Platform_Windows,
	Platform_Linux,
	Platform_Mac
}

enum PatchFunction
{
	PatchFunction_Think,
	PatchFunction_Touch
}

new Handle:g_hGameConf = INVALID_HANDLE;

public OnPluginStart()
{
	g_hGameConf = LoadGameConfigFile("mvm-teleporter.games");
	if (g_hGameConf == INVALID_HANDLE)
	{
		ThrowError("Failed to load gamedata file.");
		return;
	}
	
	for (new i = 0; i < _:PatchFunction; i++)
	{
		if (!VerifyPatchGamedata(PatchFunction:i))
		{
			ThrowError("Patch verification for \"%s\" failed.", GetPatchFunctionString(PatchFunction:i));
			return;
		}
	}
	
	for (new i = 0; i < _:PatchFunction; i++)
	{
		WritePatch(PatchFunction:i, true);
	}
}

public OnPluginEnd()
{
	for (new i = 0; i < _:PatchFunction; i++)
	{
		WritePatch(PatchFunction:i, false);
	}
}

WritePatch(PatchFunction:function, bool:enable)
{
	static ThinkOriginalJump = 0;
	static TouchOriginalJump = 0;

	if (IsPatched(function) == enable)
	{
		ThrowError("Patching \"%s\" failed, invalid state.", GetPatchFunctionString(function));
	}
	
	new Address:patchAddress = GetPatchAddress(function);
	
	new Platform:platform = GetPlatform();
	switch (platform)
	{
		case Platform_Windows:
		{
			if (enable)
			{
				StoreToAddress(patchAddress, OpCode_1_NOP, NumberType_Int8);
				
				new originalJump = LoadFromAddress(patchAddress + Address:1, NumberType_Int8);
				switch (function)
				{
					case PatchFunction_Think:
					{
						ThinkOriginalJump = originalJump;
					}
					
					case PatchFunction_Touch:
					{
						TouchOriginalJump = originalJump;
					}
					
					default:
					{
						ThrowError("Invalid function \"%s\".", GetPatchFunctionString(function));
					}
				}
				
				StoreToAddress(patchAddress + Address:1, OpCode_1_NOP, NumberType_Int8);
			} else {
				StoreToAddress(patchAddress, OpCode_1_JZ, NumberType_Int8);
				
				new originalJump;
				switch (function)
				{
					case PatchFunction_Think:
					{
						originalJump = ThinkOriginalJump;
					}
					
					case PatchFunction_Touch:
					{
						originalJump = TouchOriginalJump;
					}
					
					default:
					{
						ThrowError("Invalid function \"%s\".", GetPatchFunctionString(function));
					}
				}
				
				StoreToAddress(patchAddress, originalJump, NumberType_Int8);
			}
		}
		
		case Platform_Linux:
		{
			if (enable)
			{
				StoreToAddress(patchAddress, OpCode_1_NOP, NumberType_Int8);
				StoreToAddress(patchAddress + Address:1, OpCode_1_JMP, NumberType_Int8);
			} else {
				StoreToAddress(patchAddress, OpCode_1_TWOBYTE, NumberType_Int8);
				StoreToAddress(patchAddress + Address:1, OpCode_2_JNZ, NumberType_Int8);
			}
		}
		
		default:
		{
			ThrowError("Invalid platform \"%d\".", _:platform);
		}
	}
}

bool:VerifyPatchGamedata(PatchFunction:function)
{
	new Address:baseAddress = GetPatchBase(function);
	new functionGameRules = LoadFromAddress(baseAddress + Address:2, NumberType_Int32);
	
	new realGameRules = FindSendPropOffs("CTFGameRulesProxy", "m_bPlayingMannVsMachine");
	
	if (functionGameRules != realGameRules)
	{
		ThrowError("Patch verification for \"%s\" failed, \"m_bPlayingMannVsMachine\" offset mismatch. (%d != %d)", GetPatchFunctionString(function), functionGameRules, realGameRules);
		return false;
	}
	
	new bool:opCodeValid = false;
	
	new Address:patchAddress = GetPatchAddress(function);
	new opCode1 = LoadFromAddress(patchAddress, NumberType_Int8);
	
	if (opCode1 == OpCode_1_NOP)
	{
		ThrowError("Patch verification for \"%s\" failed, already patched.", GetPatchFunctionString(function));
		return false;
	}
	
	new opCode2;
	
	new Platform:platform = GetPlatform();
	switch (platform)
	{
		case Platform_Windows:
		{
			opCodeValid = (opCode1 == OpCode_1_JZ);
		}
		
		case Platform_Linux:
		{
			opCode2 = LoadFromAddress(patchAddress + Address:1, NumberType_Int8);
			opCodeValid = ((opCode1 == OpCode_1_TWOBYTE) && (opCode2 == OpCode_2_JNZ));
		}
		
		default:
		{
			ThrowError("Invalid platform \"%d\".", _:platform);
			return false;
		}
	}
	
	if (!opCodeValid)
	{
		ThrowError("Patch verification for \"%s\" failed, opcode at patch address didn't match.", GetPatchFunctionString(function));
		return false;
	}
	
	return true;
}

bool:IsPatched(PatchFunction:function)
{
	new Address:patchAddress = GetPatchAddress(function);
	new opCode = LoadFromAddress(patchAddress, NumberType_Int8);
	
	return (opCode == OpCode_1_NOP);
}

Address:GetPatchAddress(PatchFunction:function)
{
	new Address:baseAddress = GetPatchBase(function);
	new Address:patchOffset = Address_Null;
	
	new Platform:platform = GetPlatform();
	switch (platform)
	{
		case Platform_Windows:
		{
			switch (function)
			{
				case PatchFunction_Think:
				{
					patchOffset = Address:10;
				}
				
				case PatchFunction_Touch:
				{
					patchOffset = Address:6;
				}
				
				default:
				{
					ThrowError("Invalid function \"%s\".", GetPatchFunctionString(function));
					return Address_Null;
				}
			}
		}
		
		case Platform_Linux:
		{
			switch (function)
			{
				case PatchFunction_Think:
				{
					patchOffset = Address:7;
				}
				
				case PatchFunction_Touch:
				{
					patchOffset = Address:7;
				}
				
				default:
				{
					ThrowError("Invalid function \"%s\".", GetPatchFunctionString(function));
					return Address_Null;
				}
			}
		}
		
		default:
		{
			ThrowError("Invalid platform \"%d\".", _:platform);
			return Address_Null;
		}
	}
	
	return baseAddress + patchOffset;
}

Address:GetPatchBase(PatchFunction:function)
{
	static Address:ThinkBase = Address_Null;
	static Address:TouchBase = Address_Null;
	
	switch (function)
	{
		case PatchFunction_Think:
		{
			if (ThinkBase != Address_Null)
				return ThinkBase;
		}
		
		case PatchFunction_Touch:
		{
			if (TouchBase != Address_Null)
				return TouchBase;
		}
		
		default:
		{
			ThrowError("Invalid function \"%s\".", GetPatchFunctionString(function));
			return Address_Null;
		}
	}
	
	new Address:functionBase = GameConfGetAddress(g_hGameConf, GetPatchFunctionString(function));
	functionBase += Address:GameConfGetOffset(g_hGameConf, GetPatchFunctionString(function));
	
	switch (function)
	{
		case PatchFunction_Think:
		{
			ThinkBase = functionBase;
		}
		
		case PatchFunction_Touch:
		{
			TouchBase = functionBase;
		}
		
		default:
		{
			ThrowError("Invalid function \"%s\".", GetPatchFunctionString(function));
			return Address_Null;
		}
	}
	
	return functionBase;
}

String:GetPatchFunctionString(PatchFunction:function)
{
	new String:buffer[16];
	switch (function)
	{
		case PatchFunction_Think:
		{
			buffer = "TeleporterThink";
			return buffer;
		}
	
		case PatchFunction_Touch:
		{
			buffer = "TeleporterTouch";
			return buffer;
		}
	
		default:
		{
			ThrowError("Invalid function \"%d\".", _:function);
			return buffer;
		}
	}
	
	// We can't ever actually get here, but we want to make the compiler happy.
	return buffer;
}

Platform:GetPlatform()
{
	static Platform:ResolvedPlatform = Platform_Invalid;
	
	if (ResolvedPlatform == Platform_Invalid)
	{
		ResolvedPlatform = Platform:GameConfGetOffset(g_hGameConf, "PlatformDetection");
		
		if (Platform_Invalid >= ResolvedPlatform >= Platform)
		{
			ThrowError("Unknown platform \"%d\" detected.", _:ResolvedPlatform);
			return Platform_Invalid;
		}
	}
	
	return ResolvedPlatform;
}
