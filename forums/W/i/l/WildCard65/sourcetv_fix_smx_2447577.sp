java.lang.NullPointerException
	at lysis.lstructure.LBlock.last(LBlock.java:175)
	at lysis.lstructure.LBlock.numSuccessors(LBlock.java:119)
	at lysis.builder.structure.BlockAnalysis.Order(BlockAnalysis.java:36)
	at lysis.builder.MethodParser.buildBlocks(MethodParser.java:815)
	at lysis.builder.MethodParser.parse(MethodParser.java:872)
	at lysis.Lysis.PreprocessMethod(Lysis.java:32)
	at lysis.Lysis.main(Lysis.java:180)

/* ERROR PREPROCESSING! null */
 function "OxOOOOOO5C" (number 20)
public PlVers:__version =
{
	version = 5,
	filevers = "1.6.4-dev+4615",
	date = "08/12/2016",
	time = "15:59:45"
};
new Float:NULL_VECTOR[3];
new String:NULL_STRING[4];
public Extension:__ext_core =
{
	name = "Core",
	file = "core",
	autoload = 0,
	required = 0,
};
new MaxClients;
java.lang.StringIndexOutOfBoundsException: String index out of range: 678624805
	at java.lang.String.checkBounds(Unknown Source)
	at java.lang.String.<init>(Unknown Source)
	at lysis.sourcepawn.SourcePawnFile.ReadString(SourcePawnFile.java:116)
	at lysis.sourcepawn.SourcePawnFile.stringFromData(SourcePawnFile.java:1097)
	at lysis.builder.SourceBuilder.writeGlobal(SourceBuilder.java:1167)
	at lysis.builder.SourceBuilder.writeGlobals(SourceBuilder.java:1287)
	at lysis.Lysis.main(Lysis.java:193)
public __ext_core_SetNTVOptional()
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
	MarkNativeAsOptional("BfWriteEntity");
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

bool:StrEqual(String:str1[], String:str2[], bool:caseSensitive)
{
	return strcmp(str1, str2, caseSensitive) == 0;
}

ReplyToTargetError(client, reason)
{
	switch (reason)
	{
		case -7:
		{
			ReplyToCommand(client, "[SM] %t", "More than one client matched");
		}
		case -6:
		{
			ReplyToCommand(client, "[SM] %t", "Cannot target bot");
		}
		case -5:
		{
			ReplyToCommand(client, "[SM] %t", "No matching clients");
		}
		case -4:
		{
			ReplyToCommand(client, "[SM] %t", "Unable to target");
		}
		case -3:
		{
			ReplyToCommand(client, "[SM] %t", "Target is not in game");
		}
		case -2:
		{
			ReplyToCommand(client, "[SM] %t", "Target must be dead");
		}
		case -1:
		{
			ReplyToCommand(client, "[SM] %t", "Target must be alive");
		}
		case 0:
		{
			ReplyToCommand(client, "[SM] %t", "No matching client");
		}
		default:
		{
		}
	}
	return 0;
}

FindTarget(client, String:target[], bool:nobots, bool:immunity)
{
	decl String:target_name[64];
	decl target_list[1];
	decl target_count;
	decl bool:tn_is_ml;
	new flags = 16;
	if (nobots)
	{
		flags |= 32;
	}
	if (!immunity)
	{
		flags |= 8;
	}
	if (0 < (target_count = ProcessTargetString(target, client, target_list, 1, flags, target_name, 64, tn_is_ml)))
	{
		return target_list[0];
	}
	ReplyToTargetError(client, target_count);
	return -1;
}

public PoweredBySmartPawn()
{
	return 0;
}

java.lang.IndexOutOfBoundsException: Index: -1, Size: 0
	at java.util.LinkedList.checkElementIndex(Unknown Source)
	at java.util.LinkedList.get(Unknown Source)
	at lysis.nodes.AbstractStack.popEntry(AbstractStack.java:60)
	at lysis.nodes.AbstractStack.pop(AbstractStack.java:66)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:148)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.buildNodes(NodeBuilder.java:742)
	at lysis.Lysis.DumpMethod(Lysis.java:69)
	at lysis.Lysis.main(Lysis.java:205)

/* ERROR! Index: -1, Size: 0 */
 function "OnPluginStart" (number 5)
java.lang.OutOfMemoryError: Java heap space
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:714)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.buildNodes(NodeBuilder.java:742)
	at lysis.Lysis.DumpMethod(Lysis.java:69)
	at lysis.Lysis.main(Lysis.java:205)

/* ERROR! Java heap space */
 function "OxOOOOOOOO" (number 6)
java.lang.IndexOutOfBoundsException: Index: -1, Size: 0
	at java.util.LinkedList.checkElementIndex(Unknown Source)
	at java.util.LinkedList.get(Unknown Source)
	at lysis.nodes.AbstractStack.popEntry(AbstractStack.java:60)
	at lysis.nodes.AbstractStack.pop(AbstractStack.java:66)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:148)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.buildNodes(NodeBuilder.java:742)
	at lysis.Lysis.DumpMethod(Lysis.java:69)
	at lysis.Lysis.main(Lysis.java:205)

/* ERROR! Index: -1, Size: 0 */
 function "OxOOOOOOO5" (number 7)
java.lang.OutOfMemoryError: Java heap space
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:714)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.buildNodes(NodeBuilder.java:742)
	at lysis.Lysis.DumpMethod(Lysis.java:69)
	at lysis.Lysis.main(Lysis.java:205)

/* ERROR! Java heap space */
 function "OxOOOOOOO1" (number 8)
java.lang.OutOfMemoryError: Java heap space
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:714)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.buildNodes(NodeBuilder.java:742)
	at lysis.Lysis.DumpMethod(Lysis.java:69)
	at lysis.Lysis.main(Lysis.java:205)

/* ERROR! Java heap space */
 function "OxOOOOOOOC" (number 9)
java.lang.IndexOutOfBoundsException: Index: -1, Size: 0
	at java.util.LinkedList.checkElementIndex(Unknown Source)
	at java.util.LinkedList.get(Unknown Source)
	at lysis.nodes.AbstractStack.popEntry(AbstractStack.java:60)
	at lysis.nodes.AbstractStack.pop(AbstractStack.java:66)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:148)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.buildNodes(NodeBuilder.java:742)
	at lysis.Lysis.DumpMethod(Lysis.java:69)
	at lysis.Lysis.main(Lysis.java:205)

/* ERROR! Index: -1, Size: 0 */
 function "OxOOOOOOO8" (number 10)
java.lang.IndexOutOfBoundsException: Index: -1, Size: 0
	at java.util.LinkedList.checkElementIndex(Unknown Source)
	at java.util.LinkedList.get(Unknown Source)
	at lysis.nodes.AbstractStack.popEntry(AbstractStack.java:60)
	at lysis.nodes.AbstractStack.pop(AbstractStack.java:66)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:148)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.buildNodes(NodeBuilder.java:742)
	at lysis.Lysis.DumpMethod(Lysis.java:69)
	at lysis.Lysis.main(Lysis.java:205)

/* ERROR! Index: -1, Size: 0 */
 function "AskPluginLoad2" (number 11)
java.lang.OutOfMemoryError: Java heap space
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:714)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.buildNodes(NodeBuilder.java:742)
	at lysis.Lysis.DumpMethod(Lysis.java:69)
	at lysis.Lysis.main(Lysis.java:205)

/* ERROR! Java heap space */
 function "OxOOOOOOF4" (number 12)
java.lang.OutOfMemoryError: Java heap space

/* ERROR! Java heap space */
 function "OxOOOOOOFB" (number 13)
java.lang.IndexOutOfBoundsException: Index: -1, Size: 0
	at java.util.LinkedList.checkElementIndex(Unknown Source)
	at java.util.LinkedList.get(Unknown Source)
	at lysis.nodes.AbstractStack.popEntry(AbstractStack.java:60)
	at lysis.nodes.AbstractStack.pop(AbstractStack.java:66)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:148)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.buildNodes(NodeBuilder.java:742)
	at lysis.Lysis.DumpMethod(Lysis.java:69)
	at lysis.Lysis.main(Lysis.java:205)

/* ERROR! Index: -1, Size: 0 */
 function "OxOOOOOO5E" (number 14)
java.lang.OutOfMemoryError: Java heap space

/* ERROR! Java heap space */
 function "OxOOOOOO56" (number 15)
java.lang.OutOfMemoryError: Java heap space

/* ERROR! Java heap space */
 function "OxOOOOO4CA" (number 16)
java.lang.IndexOutOfBoundsException: Index: -1, Size: 0
	at java.util.LinkedList.checkElementIndex(Unknown Source)
	at java.util.LinkedList.get(Unknown Source)
	at lysis.nodes.AbstractStack.popEntry(AbstractStack.java:60)
	at lysis.nodes.AbstractStack.pop(AbstractStack.java:66)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:148)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.traverse(NodeBuilder.java:735)
	at lysis.nodes.NodeBuilder.buildNodes(NodeBuilder.java:742)
	at lysis.Lysis.DumpMethod(Lysis.java:69)
	at lysis.Lysis.main(Lysis.java:205)

/* ERROR! Index: -1, Size: 0 */
 function "OxOOOOO484" (number 17)
java.lang.OutOfMemoryError: Java heap space

/* ERROR! Java heap space */
 function "OxOOOOO48E" (number 18)
java.lang.OutOfMemoryError: Java heap space

/* ERROR! Java heap space */
 function "OxOOOOO4C6" (number 19)
java.lang.NullPointerException
	at lysis.lstructure.LBlock.last(LBlock.java:175)
	at lysis.lstructure.LBlock.numSuccessors(LBlock.java:119)
	at lysis.builder.structure.BlockAnalysis.Order(BlockAnalysis.java:36)
	at lysis.builder.MethodParser.buildBlocks(MethodParser.java:815)
	at lysis.builder.MethodParser.parse(MethodParser.java:872)
	at lysis.Lysis.DumpMethod(Lysis.java:65)
	at lysis.Lysis.main(Lysis.java:205)

/* ERROR! null */
 function "OxOOOOOO5C" (number 20)
java.lang.OutOfMemoryError: Java heap space

/* ERROR! Java heap space */
 function "OxOOOOO4EC" (number 21)
OxOOOOO4BB(OxOOOOO4B7)
{
	return OxOOOOO4B7 * 1;
}

OxOOOOO4B6(OxOOOOO4BA)
{
	return OxOOOOO4BA * 1;
}

OxOOOOO4B3(OxOOOOO4BD)
{
	return OxOOOOO4BD * 1;
}

OxOOOOO47O(OxOOOOO474)
{
	return OxOOOOO474 * 1;
}

OxOOOOO47F(OxOOOOO475)
{
	return OxOOOOO475 * 1;
}

OxOOOOO471(OxOOOOO47C)
{
	return OxOOOOO47C * 1;
}

OxOOOOO478(OxOOOOO47E)
{
	return OxOOOOO47E * 1;
}

