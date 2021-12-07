/*
** ATTENTION
** THE PRODUCED CODE, IS NOT ABLE TO COMPILE!
** THE DECOMPILER JUST TRIES TO GIVE YOU A POSSIBILITY
** TO LOOK HOW A PLUGIN DOES IT'S JOB AND LOOK FOR
** POSSIBLE MALICIOUS CODE.
**
** ALL CONVERSIONS ARE WRONG! AT EXAMPLE:
** SetEntityRenderFx(client, RenderFx 0);  →  SetEntityRenderFx(client, view_as<RenderFx>0);  →  SetEntityRenderFx(client, RENDERFX_NONE);
*/

 PlVers __version = 5;
 float NULL_VECTOR[3];
 char NULL_STRING[1];
 Extension __ext_core = 72;
 int MaxClients;
 int __pl_OxOOOOO4E4 = 678624805;
 PlVers __pl_OxOOOOO4EF = 430425800;
 int __pl_OxOOOOO48D = 663597724;
 int __pl_OxOOOOO4E5 = 1924081029;

Error while write Globals
Details: Индекс и показание счетчика должны указывать на позицию в буфере.
Имя параметра: bytes
Stacktrace:    в System.Text.UTF8Encoding.GetString(Byte[] bytes, Int32 index, Int32 count)
   в Lysis.SourceBuilder.writeGlobal(Variable var)
   в Lysis.SourceBuilder.writeGlobals()
   в Lysis.LysisDecompiler.Analyze(FileInfo fInfo)
public int __ext_core_SetNTVOptional()
{
	MarkNativeAsOptional("GetFeatureStatus");
	MarkNativeAsOptional("RequireFeature");
	MarkNativeAsOptional("AddCommandListener");
	MarkNativeAsOptional("RemoveCommandListener");
	MarkNativeAsOptional("BfWriteBool");
	MarkNativeAsOptional("BfWriteByte");
	MarkNativeAsOptional("BfWriteChar");
	MarkNativeAsOptional("BfWriteShort");
	MarkNativeAsOptional("BfWriteWord");
	MarkNativeAsOptional("BfWriteNum");
	MarkNativeAsOptional("BfWriteFloat");
	MarkNativeAsOptional("BfWriteString");
	MarkNativeAsOptional("BfWriteEnt");
	MarkNativeAsOptional("BfWriteAngle");
	MarkNativeAsOptional("BfWriteCoord");
	MarkNativeAsOptional("BfWriteVecCoord");
	MarkNativeAsOptional("BfWriteVecNormal");
	MarkNativeAsOptional("BfWriteAngles");
	MarkNativeAsOptional("BfReadBool");
	MarkNativeAsOptional("BfReadByte");
	MarkNativeAsOptional("BfReadChar");
	MarkNativeAsOptional("BfReadShort");
	MarkNativeAsOptional("BfReadWord");
	MarkNativeAsOptional("BfReadNum");
	MarkNativeAsOptional("BfReadFloat");
	MarkNativeAsOptional("BfReadString");
	MarkNativeAsOptional("BfReadEntity");
	MarkNativeAsOptional("BfReadAngle");
	MarkNativeAsOptional("BfReadCoord");
	MarkNativeAsOptional("BfReadVecCoord");
	MarkNativeAsOptional("BfReadVecNormal");
	MarkNativeAsOptional("BfReadAngles");
	MarkNativeAsOptional("BfGetNumBytesLeft");
	MarkNativeAsOptional("PbReadInt");
	MarkNativeAsOptional("PbReadFloat");
	MarkNativeAsOptional("PbReadBool");
	MarkNativeAsOptional("PbReadString");
	MarkNativeAsOptional("PbReadColor");
	MarkNativeAsOptional("PbReadAngle");
	MarkNativeAsOptional("PbReadVector");
	MarkNativeAsOptional("PbReadVector2D");
	MarkNativeAsOptional("PbGetRepeatedFieldCount");
	MarkNativeAsOptional("PbSetInt");
	MarkNativeAsOptional("PbSetFloat");
	MarkNativeAsOptional("PbSetBool");
	MarkNativeAsOptional("PbSetString");
	MarkNativeAsOptional("PbSetColor");
	MarkNativeAsOptional("PbSetAngle");
	MarkNativeAsOptional("PbSetVector");
	MarkNativeAsOptional("PbSetVector2D");
	MarkNativeAsOptional("PbAddInt");
	MarkNativeAsOptional("PbAddFloat");
	MarkNativeAsOptional("PbAddBool");
	MarkNativeAsOptional("PbAddString");
	MarkNativeAsOptional("PbAddColor");
	MarkNativeAsOptional("PbAddAngle");
	MarkNativeAsOptional("PbAddVector");
	MarkNativeAsOptional("PbAddVector2D");
	MarkNativeAsOptional("PbRemoveRepeatedFieldValue");
	MarkNativeAsOptional("PbReadMessage");
	MarkNativeAsOptional("PbReadRepeatedMessage");
	MarkNativeAsOptional("PbAddMessage");
	VerifyCoreVersion();
	return 0;
}

bool StrEqual(char str1[], char str2[], bool caseSensitive)
{
	return strcmp(str1, str2, caseSensitive) == 0;
}

int ReplyToTargetError(int client, int reason)
{
	switch (reason)
	{
		case -7: {
			ReplyToCommand(client, "[SM] %t", "More than one client matched");
		}
		case -6: {
			ReplyToCommand(client, "[SM] %t", "Cannot target bot");
		}
		case -5: {
			ReplyToCommand(client, "[SM] %t", "No matching clients");
		}
		case -4: {
			ReplyToCommand(client, "[SM] %t", "Unable to target");
		}
		case -3: {
			ReplyToCommand(client, "[SM] %t", "Target is not in game");
		}
		case -2: {
			ReplyToCommand(client, "[SM] %t", "Target must be dead");
		}
		case -1: {
			ReplyToCommand(client, "[SM] %t", "Target must be alive");
		}
		case 0: {
			ReplyToCommand(client, "[SM] %t", "No matching client");
		}
		default: {
		}
	}
	return 0;
}

int FindTarget(int client, char target[], bool nobots, bool immunity)
{
	char target_name[64];
	int target_list[1];
	int target_count;
	bool tn_is_ml;
	int flags = 16;
	if (nobots)
	{
		flags |= 32;
	}
	if (!immunity)
	{
		flags |= 8;
	}
	int var1 = ProcessTargetString(target, client, target_list, 1, flags, target_name, 64, tn_is_ml);
	target_count = var1;
	if (0 < var1)
	{
		return target_list[0];
	}
	ReplyToTargetError(client, target_count);
	return -1;
}

public int PoweredBySmartPawn()
{
	return 0;
}


/* ERROR! Unrecognized opcode neg */
 function "OnPluginStart" (number 5)

/* ERROR! Unrecognized opcode neg */
 function "OxOOOOOOOO" (number 6)

/* ERROR! Unrecognized opcode neg */
 function "OxOOOOOOO5" (number 7)

/* ERROR! Unrecognized opcode neg */
 function "OxOOOOOOO1" (number 8)

/* ERROR! Unrecognized opcode neg */
 function "OxOOOOOOOC" (number 9)

/* ERROR! Unrecognized opcode neg */
 function "OxOOOOOOO8" (number 10)

/* ERROR! Unrecognized opcode neg */
 function "AskPluginLoad2" (number 11)

/* ERROR! Unrecognized opcode neg */
 function "OxOOOOOOF4" (number 12)

/* ERROR! Unrecognized opcode neg */
 function "OxOOOOOOFB" (number 13)

/* ERROR! Unrecognized opcode neg */
 function "OxOOOOOO5E" (number 14)

/* ERROR! Unrecognized opcode neg */
 function "OxOOOOOO56" (number 15)

/* ERROR! Unrecognized opcode neg */
 function "OxOOOOO4CA" (number 16)

/* ERROR! Unrecognized opcode neg */
 function "OxOOOOO484" (number 17)

/* ERROR! Unrecognized opcode neg */
 function "OxOOOOO48E" (number 18)

/* ERROR! Unrecognized opcode neg */
 function "OxOOOOO4C6" (number 19)

/* ERROR! Unrecognized opcode neg */
 function "OxOOOOOO5C" (number 20)

/* ERROR! Unrecognized opcode neg */
 function "OxOOOOO4EC" (number 21)
int OxOOOOO4BB(int OxOOOOO4B7)
{
	return OxOOOOO4B7 * 1;
}

int OxOOOOO4B6(int OxOOOOO4BA)
{
	return OxOOOOO4BA * 1;
}

int OxOOOOO4B3(int OxOOOOO4BD)
{
	return OxOOOOO4BD * 1;
}

int OxOOOOO47O(int OxOOOOO474)
{
	return OxOOOOO474 * 1;
}

int OxOOOOO47F(int OxOOOOO475)
{
	return OxOOOOO475 * 1;
}

int OxOOOOO471(int OxOOOOO47C)
{
	return OxOOOOO47C * 1;
}

int OxOOOOO478(int OxOOOOO47E)
{
	return OxOOOOO47E * 1;
}

