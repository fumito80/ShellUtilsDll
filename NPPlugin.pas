{
  Delphi framework for NS plugins
  Based on code by Matej Spiller-Muys
  Further developed by Yury Sidorov
  Details here: https://www.mozdev.org/bugs/show_bug.cgi?id=8708
}
unit NPPlugin;

interface

uses
  Windows, SysUtils, Classes;

const
  NP_VERSION_MAJOR = 0 ;
  NP_VERSION_MINOR = 19 ;

(*
 * Values for mode passed to NPP_New:
 *)
  NP_EMBED = 1 ;
  NP_FULL  = 2 ;

(*
 * Values for stream type passed to NPP_NewStream:
 *)
  NP_NORMAL     = 1 ;
  NP_SEEK       = 2 ;
  NP_ASFILE     = 3 ;
  NP_ASFILEONLY = 4 ;

  NP_MAXREADY = ( ( cardinal( not 0 ) shl 1 ) shr 1 ) ;

(*----------------------------------------------------------------------*/
/*                   Error and Reason Code definitions                  */
/*----------------------------------------------------------------------*)

(*
 *	Values of type NPError:
 *)
  NPERR_BASE                       = 0 ;
  NPERR_NO_ERROR                   = NPERR_BASE + 0 ;
  NPERR_GENERIC_ERROR              = NPERR_BASE + 1 ;
  NPERR_INVALID_INSTANCE_ERROR     = NPERR_BASE + 2 ;
  NPERR_INVALID_FUNCTABLE_ERROR    = NPERR_BASE + 3 ;
  NPERR_MODULE_LOAD_FAILED_ERROR   = NPERR_BASE + 4 ;
  NPERR_OUT_OF_MEMORY_ERROR        = NPERR_BASE + 5 ;
  NPERR_INVALID_PLUGIN_ERROR       = NPERR_BASE + 6 ;
  NPERR_INVALID_PLUGIN_DIR_ERROR   = NPERR_BASE + 7 ;
  NPERR_INCOMPATIBLE_VERSION_ERROR = NPERR_BASE + 8 ;
  NPERR_INVALID_PARAM              = NPERR_BASE + 9 ;
  NPERR_INVALID_URL                = NPERR_BASE + 10 ;
  NPERR_FILE_NOT_FOUND             = NPERR_BASE + 11 ;
  NPERR_NO_DATA                    = NPERR_BASE + 12 ;
  NPERR_STREAM_NOT_SEEKABLE        = NPERR_BASE + 13 ;

(*
 *	Values of type NPReason:
 *)
  NPRES_BASE        = 0 ;
  NPRES_DONE        = NPRES_BASE + 0 ;
  NPRES_NETWORK_ERR = NPRES_BASE + 1 ;
  NPRES_USER_BREAK  = NPRES_BASE + 2 ;

(*
 *	Don't use these obsolete error codes any more.
 *
  NP_NOERR  NP_NOERR_is_obsolete_use_NPERR_NO_ERROR
  NP_EINVAL NP_EINVAL_is_obsolete_use_NPERR_GENERIC_ERROR
  NP_EABORT NP_EABORT_is_obsolete_use_NPRES_USER_BREAK *)

(*
 * Version feature information
 *)
  NPVERS_HAS_STREAMOUTPUT      = 8 ;
  NPVERS_HAS_NOTIFICATION      = 9 ;
  NPVERS_HAS_LIVECONNECT       = 9 ;
  NPVERS_WIN16_HAS_LIVECONNECT = 10 ;

type
  TJRIRef = pointer ;
  TJRIGlobalRef = pointer ;
  TJRIEnvInterface = record end ;
  PJRIEnvInterface = ^TJRIEnvInterface ;

  { synonyms: }
  TJGlobal = TJRIGlobalRef ;
  TJRef    = TJRIRef ;
  PJRIEnv  = PJRIEnvInterface ;

  TPCharArray = array[ 0..( Maxint - 16 ) div SizeOf( PChar ) - 1 ] of PChar ;
  TNPBool     = char ;
  TNPMIMEType = PChar ;
  TNPError    = smallint ;
  TNPReason   = smallint ;
  TNPEvent    = pointer ;

  //List of variable names for which NPP_GetValue shall be implemented
  TNPPVariable = Integer;

const
    NPPVpluginNameString = 1;
    NPPVpluginDescriptionString = 2;
    NPPVpluginWindowBool = 3;
    NPPVpluginTransparentBool = 4;
    NPPVjavaClass = 5;              { Not implemented in Mozilla 1.0 }
    NPPVpluginWindowSize = 6;
    NPPVpluginTimerInterval = 7;

//TDB    NPPVpluginScriptableInstance = (10 | NP_ABI_MASK),
    NPPVpluginScriptableIID = 11;

    { Introduced in Mozilla 0.9.9 }
    NPPVjavascriptPushCallerBool = 12;

    { Introduced in Mozilla 1.0 }
    NPPVpluginKeepLibraryInMemory = 13;
    NPPVpluginNeedsXEmbed         = 14;

    { Get the NPObject for scripting the plugin. Introduced in Firefox
     1.0 (NPAPI minor version 14). }
    NPPVpluginScriptableNPObject  = 15;

   { Get the plugin value (as \0-terminated UTF-8 string data) for
     form submission if the plugin is part of a form. Use
     NPN_MemAlloc() to allocate memory for the string data. Introduced
     in Mozilla 1.8b2 (NPAPI minor version 15). }
    NPPVformValue = 16;
{
 #ifdef XP_MACOSX
   /* Used for negotiating drawing models */
   , NPPVpluginDrawingModel = 1000
 #endif
}

// List of variable names for which NPN_GetValue is implemented by a browser
type
  TNPNVariable = Integer;

const  
  NPNVxDisplay = 1;
  NPNVxtAppContext = 2;
  NPNVnetscapeWindow = 3;
  NPNVjavascriptEnabledBool = 4;
  NPNVasdEnabledBool = 5;
  NPNVisOfflineBool = 6;
  // 10 and over are available on Mozilla builds starting with 0.9.4
  NPNVserviceManager = 10;
  NPNVDOMElement     = 11;   // available in Mozilla 1.2
  NPNVDOMWindow      = 12;
  NPNVToolkit        = 13;
  NPNVSupportsXEmbedBool = 14;
  // Get the NPObject wrapper for the browser window.
  NPNVWindowNPObject = 15;
  // Get the NPObject wrapper for the plugins DOM element.
  NPNVPluginElementNPObject = 16;

type
  PNPP = ^TNPP ;
  TNPP = record
    PData : pointer ; { plug-in private data }
    NData : pointer ; { netscape private data }
  end ;

  PNPSavedData = ^TNPSavedData ;
  TNPSavedData = record
    Len : longint ;
    Buf : pointer ;
  end ;

  PNPRect = ^TNPRect ;
  TNPRect = record
    Top    : SmallInt ;
    Left   : SmallInt ;
    Bottom : SmallInt ;
    Right  : SmallInt ;
  end ;

  PNPWindow = ^TNPWindow ;
  TNPWindow = record
    Window   : longint ; { Platform specific window handle }
    x        : longint ; { Position of top left corner relative }
    y        : longint ; {   to a netscape page.                }
    Width    : longint ; { Maximum window size }
    Height   : longint ;
    ClipRect : TNPRect ; { Clipping rectangle in port coordinates }
                         {                      Used by MAC only. }
  end ;


  PNPByteRange = ^TNPByteRange ;
  TNPByteRange = record
    Offset : longint ; { negative offset means from the end }
    Length : longint ;
    Next   : PNPByteRange ;
  end ;

  PNPStream = ^TNPStream ;
  TNPStream = record
    PData        : pointer ;  { plug-in private data  }
    NData        : pointer ;  { netscape private data }
    URL          : PChar ;
    EndPos       : longint ;
    LastModified : longint ;
    NotifyData   : pointer ;
  end ;

  PNPFullPrint = ^TNPFullPrint ;
  TNPFullPrint = record
    PluginPrinted : TNPBool ; { Set TRUE if plugin handled fullscreen }
                              {   printing.                           }
    PrintOne      : TNPBool ; { TRUE if plugin should print one copy  }
                              {   to default printer.                 }
    PlatformPrint : pointer ; { Platform-specific printing info       }
  end ;

  PNPEmbedPrint = ^TNPEmbedPrint ;
  TNPEmbedPrint = record
    Window        : TNPWindow ;
    PlatformPrint : pointer ; { Platform-specific printing info       }
  end ;

  PNPPrint = ^TNPPrint ;
  TNPPrint = record
    Mode : SmallInt ;  { NP_FULL or NP_EMBED }
    case integer of
      0 : ( FullPrint  : TNPFullPrint ) ; { if mode is NP_FULL }
      1 : ( EmbedPrint : TNPEmbedPrint ) ; { if mode is NP_EMBED }
  end ;

  JRIRef = pointer ;
  JRef   = JRIRef ;




const
  NP_CLASS_STRUCT_VERSION_CTOR = 1;

  // NPVariant types
  NPVARIANTTYPE_VOID    = 0;
  NPVARIANTTYPE_NULL    = 1;
  NPVARIANTTYPE_BOOL    = 2;
  NPVARIANTTYPE_INT32   = 3;
  NPVARIANTTYPE_DOUBLE  = 4;
  NPVARIANTTYPE_STRING  = 5;
  NPVARIANTTYPE_OBJECT  = 6;

type
  THRGN = type LongWord;      // duplicate def in Windows.pas
  TNPRegion = THRGN;
  TNPIdentifier = Pointer;
  PNPIdentifier = ^TNPIdentifier;
  PNPUTF8 = PChar;
  PPNPUTF8 = ^PNPUTF8;

  (* These two declarations follow far below. *)
  PNPClass = ^TNPClass;
  PNPObject = ^TNPObject;
  PPNPObject = ^PNPObject;

  PNPString = ^TNPString;
  TNPString = record
    utf8characters: PNPUTF8;
    utf8length: Cardinal;
  end;

  PNPVariant = ^TNPVariant;

  {type for replace 'union' in C++}
  TValueUnion = record
    case integer of
      1: (boolValue: ByteBool);
      2: (intValue: Integer);
      3: (doubleValue: Double);
      4: (stringValue: TNPString);
      5: (objectValue: PNPObject);
  end;

  TNPVariant = record
    _type: Integer;   {see NPVARIANTTYPE_* values}
    value: TValueUnion;
  end;

  TNPAllocateFunctionPtr = function(npp: PNPP; aClass: PNPClass): PNPObject; cdecl;
  TNPDeallocateFunctionPtr = procedure(npobj: PNPObject); cdecl;
  TNPInvalidateFunctionPtr = procedure(npobj: PNPObject); cdecl;
  TNPHasMethodFunctionPtr = function(npobj: PNPObject; name: TNPIdentifier): Boolean; cdecl;
  TNPInvokeFunctionPtr = function(npobj: PNPObject; name: TNPIdentifier; const args: PNPVariant; argCount: Cardinal; result: PNPVariant): Boolean; cdecl;
  TNPInvokeDefaultFunctionPtr = function(npobj: PNPObject; const args: PNPVariant; argCount: Cardinal; result: PNPVariant): Boolean; cdecl;
  TNPHasPropertyFunctionPtr = function(npobj: PNPObject; name: TNPIdentifier): Boolean; cdecl;
  TNPGetPropertyFunctionPtr = function(npobj: PNPObject; name: TNPIdentifier; myresult: PNPVariant): Boolean; cdecl;
  TNPSetPropertyFunctionPtr = function(npobj: PNPObject; name: TNPIdentifier; value: PNPVariant): Boolean; cdecl;
  TNPRemovePropertyFunctionPtr = function(npobj: PNPObject; name: TNPIdentifier): Boolean; cdecl;

  TNPClass = packed record
    structVersion: Cardinal;
    allocate: TNPAllocateFunctionPtr;
    deallocate: TNPDeallocateFunctionPtr;
    invalidate: TNPInvalidateFunctionPtr;
    hasMethod: TNPHasMethodFunctionPtr;
    invoke: TNPInvokeFunctionPtr;
    invokeDefault: TNPInvokeDefaultFunctionPtr;
    hasProperty: TNPHasPropertyFunctionPtr;
    getProperty: TNPGetPropertyFunctionPtr;
    setProperty: TNPSetPropertyFunctionPtr;
    removeProperty: TNPRemovePropertyFunctionPtr;
  end;

  TNPObject = packed record
    _class: PNPClass;
    referenceCount: Cardinal;
    plugin: pointer;
  end;

procedure Write2EventLog(Source, Msg: string; eventType: Integer = EVENTLOG_ERROR_TYPE);

{ PLUGIN API TO NETSCAPE NAVIGATOR
  ================================
  The following are API functions as documented in the Netscape Plugin docs
  as of 23-Oct-96. The actual interface is via a function table. However, you
  should call these wrapper functions which take care of calling into the
  function table and also do some parameter checking.

  The function table is accessible and appears after
  the following API routines. }

procedure  NPN_Version( var PluginMajor : integer ;
                        var PluginMinor : integer ;
                        var NetscapeMajor : integer ;
                        var NetscapeMinor : integer ) ;
function  NPN_GetURLNotify( Instance : PNPP ;
                            URL      : PChar ;
                            Target   : PChar ;
                            var NotifyData ) : TNPError ;
function  NPN_GetURL( Instance : PNPP ;
                      URL      : PChar ;
                      Target   : PChar ) : TNPError ;
function  NPN_PostURLNotify( Instance : PNPP ;
                             URL      : PChar ;
                             Target   : PChar ;
                             Len      : longint ;
                             var Buf ;
                             IsFile   : TNPBool ;
                             var NotifyData ) : TNPError ;
function  NPN_PostURL( Instance : PNPP ;
                       URL      : PChar ;
                       Window   : PChar ;
                       Len      : longint ;
                       const Buf ;
                       IsFile   : TNPBool ) : TNPError ;
function  NPN_RequestRead( Stream          : PNPStream;
                           const RangeList : TNPByteRange ) : TNPError ;
function  NPN_NewStream( Instance : PNPP ;
                         MimeType : TNPMIMEType ;
                         Target   : PChar ;
                         var Stream : PNPStream ) : TNPError ;
function  NPN_Write( Instance : PNPP ;
                     Stream   : PNPStream ;
                     Len      : longint ;
                     var Buffer ) : longint ;
function  NPN_DestroyStream( Instance : PNPP ;
                             Stream   : PNPStream ;
                             Reason   : TNPReason ) : TNPError ;
procedure NPN_Status( Instance : PNPP ;
                      Message  : PChar ) ;
function  NPN_UserAgent( Instance : PNPP ) : PChar ;
function  NPN_MemAlloc( Size : longint ) : pointer ;
procedure NPN_MemFree( Ptr : pointer ) ;
procedure NPN_ReloadPlugins( ReloadPages : TNPBool ) ;
function  NPN_GetJavaEnv : PJRIEnv ;
function  NPN_GetJavaPeer( Instance : PNPP ) : TJRef ;
function  NPN_GetValue(instance: PNPP; variable: TNPNVariable; value: Pointer): TNPError;
function  NPN_SetValue(instance: PNPP; variable: TNPPVariable; value: Pointer): TNPError;

function  NPN_UTF8FromIdentifier(identifier: TNPIdentifier): PNPUTF8;
function  NPN_IntFromIdentifier(identifier: TNPIdentifier): longint;
function  NPN_GetStringIdentifier(name: PNPUTF8): TNPIdentifier;
procedure NPN_ReleaseVariantValue(variant: PNPVariant);

function  NPN_CreateObject(npp: PNPP; aClass: PNPClass): PNPObject;
function  NPN_RetainObject(npobj: PNPObject): PNPObject;
procedure NPN_ReleaseObject(npobj: PNPObject);
procedure NPN_SetException(npobj: PNPObject; msg: PNPUTF8);

{ End of Plugin API functions to Netscape Navigator }

{ Netscape function table }

type
  TNPN_GetUrl = function( Instance : PNPP ;
                          URL      : PChar ;
                          Target   : PChar ) : TNPError ; cdecl ;
  TNPN_PostUrl = function ( Instance : PNPP ;
                            URL      : PChar ;
                            Target   : PChar ;
                            Len      : longint ;
                            const Buf ;
                            IsFile   : TNPBool ) : TNPError ; cdecl ;
  TNPNRequestRead = function( Stream    : PNPStream;
                              const RangeList : TNPByteRange ) : TNPError ; cdecl ;
  TNPN_NewStream = function( Instance : PNPP ;
                             MimeType : TNPMIMEType ;
                             Target   : PChar ;
                             var Stream : PNPStream ) : TNPError ; cdecl ;
  TNPN_Write = function( Instance : PNPP ;
                         Stream   : PNPStream ;
                         Len      : longint ;
                         var Buffer ) : longint ; cdecl ;
  TNPN_DestroyStream = function( Instance : PNPP ;
                                 Stream   : PNPStream ;
                                 Reason   : TNPReason ) : TNPError ; cdecl ;
  TNPN_Status = procedure( Instance : PNPP ;
                           Message  : PChar ) ; cdecl ;
  TNPN_UserAgent = function( Instance : PNPP ) : PChar ; cdecl ;
  TNPN_MemAlloc = function( Size : longint ) : pointer ; cdecl ;
  TNPN_MemFree = procedure( Ptr : pointer ) ; cdecl ;
  TNPN_MemFlush = function( Size : longint ) : pointer ; cdecl ;
  TNPN_ReloadPlugins = procedure( ReloadPages : TNPBool ) ; cdecl ;
  TNPN_GetJavaEnv = function : PJRIEnv ; cdecl ;
  TNPN_GetJavaPeer = function(Instance : PNPP ) : TJRef ; cdecl ;
  TNPN_GetURLNotify = function( Instance : PNPP ;
                                URL      : PChar ;
                                Target   : PChar ;
                                var NotifyData ) : TNPError ; cdecl ;
  TNPN_PostURLNotify = function( Instance : PNPP ;
                                 URL      : PChar ;
                                 Window   : PChar ;
                                 Len      : longint ;
                                 var Buf ;
                                 IsFile   : TNPBool ;
                                 var NotifyData ) : TNPError ; cdecl ;

  TNPN_GetValue = function(instance: PNPP; variable: TNPNVariable; value: Pointer): TNPError; cdecl;

  TNPN_SetValue = function(instance: PNPP; variable: TNPPVariable; value: Pointer): TNPError; cdecl;

  TNPN_InvalidateRect = procedure(instance: PNPP; invalidRect: PNPRect); cdecl;

  TNPN_InvalidateRegion = procedure(instance: PNPP; invalidRegion: TNPRegion); cdecl;

  TNPN_ForceRedraw = procedure(instance: PNPP); cdecl;

  TNPN_GetStringIdentifier = function(name: PNPUTF8): TNPIdentifier; cdecl;

  TNPN_GetStringIdentifiers = procedure(names: PPNPUTF8; nameCount: longint; identifiers: PNPIdentifier); cdecl;

  TNPN_GetIntIdentifier = function(intid: longint): TNPIdentifier; cdecl;

  TNPN_IdentifierIsString = function(identifier: TNPIdentifier): Boolean; cdecl;

  TNPN_UTF8FromIdentifier = function(identifier: TNPIdentifier): PNPUTF8; cdecl;

  TNPN_IntFromIdentifier = function(identifier: TNPIdentifier): longint; cdecl;

  TNPN_CreateObject = function(npp: PNPP; aClass: PNPClass): PNPObject; cdecl;

  TNPN_RetainObject = function(npobj: PNPObject): PNPObject; cdecl;

  TNPN_ReleaseObject = procedure(npobj: PNPObject); cdecl;

  TNPN_Invoke = function(npp: PNPP; npobj: PNPObject; methodName: TNPIdentifier; const args: PNPVariant; argCount: Cardinal; myresult: PNPVariant): Boolean; cdecl;

  TNPN_InvokeDefault = function(npp: PNPP; npobj: PNPObject; const args: PNPVariant; argCount: Cardinal; result: PNPVariant): Boolean; cdecl;

  TNPN_Evaluate = function(npp: PNPP; npobj: PNPObject; script: PNPString; myresult: PNPVariant): Boolean; cdecl;

  TNPN_GetProperty = function(npp: PNPP; npobj: PNPObject; propertyName: TNPIdentifier; myresult: PNPVariant): Boolean; cdecl;

  TNPN_SetProperty = function(npp: PNPP; npobj: PNPObject; propertyName: TNPIdentifier; const value: PNPVariant): Boolean; cdecl;

  TNPN_RemoveProperty = function(npp: PNPP; npobj: PNPObject; propertyName: TNPIdentifier): Boolean; cdecl;

  TNPN_HasProperty = function(npp: PNPP; npobj: PNPObject; propertyName: TNPIdentifier): Boolean; cdecl;

  TNPN_HasMethod = function(npp: PNPP; npobj: PNPObject; methodName: TNPIdentifier): Boolean; cdecl;

  TNPN_ReleaseVariantValue = procedure(variant: PNPVariant); cdecl;

  TNPN_SetException = procedure(npobj: PNPObject; msg: PNPUTF8); cdecl;


  PNPNetscapeFuncs = ^TNPNetscapeFuncs ;
  TNPNetscapeFuncs = record
    Size                 : word ;
    Version              : word ;
    GetURL               : TNPN_GetUrl ;
    PostURL              : TNPN_PostUrl ;
    RequestRead          : TNPNRequestRead ;
    NewStream            : TNPN_NewStream ;
    Write                : TNPN_Write ;
    DestroyStream        : TNPN_DestroyStream ;
    Status               : TNPN_Status ;
    UserAgent            : TNPN_UserAgent ;
    MemAlloc             : TNPN_MemAlloc ;
    MemFree              : TNPN_MemFree ;
    MemFlush             : TNPN_MemFlush ;
    ReloadPlugins        : TNPN_ReloadPlugins ;
    GetJavaEnv           : TNPN_GetJavaEnv ;
    GetJavaPeer          : TNPN_GetJavaPeer ;
    GetURLNotify         : TNPN_GetURLNotify ;
    PostURLNotify        : TNPN_PostURLNotify ;
    GetValue             : TNPN_GetValue;
    SetValue             : TNPN_SetValue;
    InvalidateRect       : TNPN_InvalidateRect;
    InvalidateRegion     : TNPN_InvalidateRegion;
    ForceRedraw          : TNPN_ForceRedraw;
    GetStringIdentifier  : TNPN_GetStringIdentifier;
    GetStringIdentifiers : TNPN_GetStringIdentifiers;
    GetIntIdentifier     : TNPN_GetIntIdentifier;
    IdentifierIsString   : TNPN_IdentifierIsString;
    UTF8FromIdentifier   : TNPN_UTF8FromIdentifier;
    IntFromIdentifier    : TNPN_IntFromIdentifier;
    CreateObject         : TNPN_CreateObject;
    RetainObject         : TNPN_RetainObject;
    ReleaseObject        : TNPN_ReleaseObject;
    Invoke               : TNPN_Invoke;
    InvokeDefault        : TNPN_InvokeDefault;
    Evaluate             : TNPN_Evaluate;
    GetProperty          : TNPN_GetProperty;
    SetProperty          : TNPN_SetProperty;
    RemoveProperty       : TNPN_RemoveProperty;
    HasProperty          : TNPN_HasProperty;
    HasMethod            : TNPN_HasMethod;
    ReleaseVariantValue  : TNPN_ReleaseVariantValue;
    SetException         : TNPN_SetException;
  end ;

type
  { Plugin function table }

  TNPP_New = function( PluginType     : TNPMIMEType ;
                       Instance : PNPP ;
                       Mode           : word ;
                       ArgC           : word ;
                       const Argn     : TPCharArray ;
                       const Argv     : TPCharArray ;
                       const Saved    : TNPSavedData ) : TNPError ; cdecl ;
  TNPP_Destroy = function( Instance : PNPP ;
                           var Save       : PNPSavedData ) : TNPError ; cdecl ;
  TNPP_SetWindow = function( Instance : PNPP ;
                             Window   : PNPWindow ) : TNPError ; cdecl ;
  TNPP_NewStream = function( Instance : PNPP ;
                             MimeType       : TNPMIMEType ;
			     Stream   : PNPStream ;
                             Seekable       : TNPBool ;
			     var SType      : word ) : TNPError ; cdecl ;
  TNPP_DestroyStream = function( Instance : PNPP ;
                                 Stream   : PNPStream ;
				 Reason         : TNPReason ) : TNPError ; cdecl ;
  TNPP_WriteReady = function( Instance : PNPP ;
                              Stream   : PNPStream ) : longint ; cdecl ;
  TNPP_Write = function( Instance : PNPP ;
                         Stream   : PNPStream ;
                         Offset         : longint ;
                         Len            : longint ;
                         var Buffer ) : longint ; cdecl ;
  TNPP_StreamAsFile = procedure( Instance : PNPP ;
                                 Stream   : PNPStream ;
                                 FName          : PChar ) ; cdecl ;
  TNPP_Print = procedure( Instance : PNPP ;
                          PlatformPrint : PNPPrint ) ; cdecl ;
  TNPP_HandleEvent = function( Instance : PNPP ;
                               var Event ) : smallint ; cdecl ;
  TNPP_URLNotify = procedure( Instance : PNPP ;
                              URL            : PChar ;
                              Reason         : TNPReason ;
                              var NotifyData ) ; cdecl ;

  TNPP_GetValue = function(instance: PNPP;
                           variable: TNPPVariable;
                           value: Pointer): TNPError; cdecl;

  // Comment from Mozilla src: shouldn't NPP_SetValue() take an NPPVariable and not an NPNVariable?
  TNPP_SetValue = function(instance: PNPP;
                           variable: TNPNVariable;
                           value: Pointer): TNPError; cdecl;

type
  PNPPluginFuncs = ^TNPPluginFuncs ;
  TNPPluginFuncs = record
    Size                 : word ;
    Version              : word ;
    New                  : TNPP_New ;
    Destroy              : TNPP_Destroy ;
    SetWindow            : TNPP_SetWindow ;
    NewStream            : TNPP_NewStream ;
    DestroyStream        : TNPP_DestroyStream ;
    StreamAsFile         : TNPP_StreamAsFile ;
    WriteReady           : TNPP_WriteReady ;
    Write                : TNPP_Write ;
    Print                : TNPP_Print ;
    HandleEvent          : TNPP_HandleEvent ;
    URLNotify            : TNPP_URLNotify ;
    JavaClass            : TJRIGlobalRef ;
    GetValue             : TNPP_GetValue ;
    SetValue             : TNPP_SetValue ;
  end ;

{ Functions exported by the Plugin DLL }

function  NP_GetEntryPoints( pFuncs : PNPPluginFuncs ) : TNPError ; stdcall ;
function  NP_Initialize( pFuncs : PNPNetscapeFuncs ) : TNPError ; stdcall ;
function  NP_Shutdown : TNPError ; stdcall ;

exports
  NP_GetEntryPoints,
  NP_Initialize,
  NP_Shutdown;

function  NPP_Initialize : TNPError ; cdecl ;
procedure NPP_Shutdown ; cdecl ;

{ Plugin functions that have to be supplied to Netscape.         }

function  NPP_New( PluginType  : TNPMIMEType ;
                   Instance    : PNPP ;
                   Mode        : word ;
                   ArgC        : word ;
                   const Argn  : TPCharArray ;
                   const Argv  : TPCharArray ;
                   const Saved : TNPSavedData ) : TNPError ; cdecl ;
function  NPP_Destroy( Instance : PNPP ;
                       var Save : PNPSavedData ) : TNPError ; cdecl ;
function  NPP_SetWindow( Instance : PNPP ;
                         Window   : PNPWindow ) : TNPError ; cdecl ;
function  NPP_NewStream( Instance  : PNPP ;
                         MimeType  : TNPMIMEType ;
                         Stream    : PNPStream ;
                         Seekable  : TNPBool ;
                         var SType : word ) : TNPError ; cdecl ;
function  NPP_DestroyStream( Instance : PNPP ;
                             Stream   : PNPStream ;
                             Reason   : TNPReason ) : TNPError ; cdecl ;
function  NPP_WriteReady( Instance : PNPP ;
                          Stream   : PNPStream ) : longint ; cdecl ;
function  NPP_Write( Instance : PNPP ;
                     Stream   : PNPStream ;
                     Offset   : longint ;
                     Len      : longint ;
                     var Buffer ) : longint ; cdecl ;
procedure  NPP_StreamAsFile( Instance : PNPP ;
                             Stream   : PNPStream ;
                             FName    : PChar ) ; cdecl ;
procedure  NPP_Print( Instance      : PNPP ;
                      PlatformPrint : PNPPrint ) ; cdecl ;
function  NPP_HandleEvent( Instance : PNPP ;
                           var Event ) : smallint ; cdecl ;
procedure NPP_URLNotify( Instance : PNPP ;
                         URL      : PChar ;
                         Reason   : TNPReason ;
                         var NotifyData ) ; cdecl ;
function  NPP_GetJavaClass : JRef ; cdecl ;

function  NPP_GetValue(instance: PNPP;
                           variable: TNPPVariable;
                           value: Pointer): TNPError; cdecl;

  // Comment from Mozilla src: shouldn't NPP_SetValue() take an NPPVariable and not an NPNVariable?
function  NPP_SetValue(instance: PNPP;
                           variable: TNPNVariable;
                           value: Pointer): TNPError; cdecl;


function  Private_GetJavaClass : TJRIGlobalRef ; cdecl ;


{ OOP Interface to Netscape }

type
  TNPApiPublicMethod = function(obj : TObject; const params: array of OleVariant): OleVariant;
  TArrayOleVariant = array of OleVariant;

  IBrowserObject = interface
    function Invoke(const MethodName: string; const Params: array of OleVariant): OleVariant;
    function InvokeDefault(const Params: array of OleVariant): OleVariant;
    function Evaluate(const Script: string): OleVariant;
    function GetProperty(const PropertyName: string): OleVariant;
    procedure SetProperty(const PropertyName: string; const Value: OleVariant);
    procedure RemoveProperty(const PropertyName: string);
    function HasProperty(const PropertyName: string): boolean;
    function HasMethod(const MethodName: string): boolean;
    function GetObject(const PropertyName: string): IBrowserObject;

    property Properties[const Index: string]: Olevariant read GetProperty write SetProperty; default;
  end;

  TBrowserType = (btInvalid, btMozilla, btOpera, btChrome, btUnknown);

{$M+}
  TPlugin = class
  private
    FInstance       : PNPP ;
    FWindowHandle   : HWnd ;
    FExtraInfo      : TObject ;
    FPluginType     : string ;
    FParamNames     : TStrings ;
    FParamValues    : TStrings ;
    m_pScriptableObject: PNPObject;
    FBrowserType: TBrowserType;

    function GetBrowserType: TBrowserType;
  protected
    procedure WindowHandleChanging ; virtual ;
    procedure WindowHandleChanged ; virtual ;
    procedure WindowChanged ; virtual ;
    function NPVariantToVariant(value: PNPVariant): Variant;
    function ConvertToArray(const args: PNPVariant; argCount: Cardinal):  TArrayOleVariant;
  public
    constructor Create( AInstance         : PNPP ;
                        AExtraInfo        : TObject ;
                        const APluginType : string ;
                        AMode             : word ;
                        AParamNames       : TStrings ;
                        AParamValues      : TStrings ;
                        const ASaved      : TNPSavedData ) ; virtual ;
    destructor Destroy ; override ;
    property Instance : PNPP read FInstance ;
    property ExtraInfo : TObject read FExtraInfo ;
    property PluginType : string read FPluginType ;
    property ParamNames : TStrings read FParamNames ;
    property ParamValues : TStrings read FParamValues ;
    property WindowHandle : HWnd read FWindowHandle ;
    class procedure Register( const MimeTypes : string ;
                              ExtraInfo       : TObject ) ;
    class function  IsInterested( const ARegisteredMimeTypes : TStrings ;
                                  const APluginType          : string ;
                                  AMode                      : word ;
                                  AParamNames                : TStrings ;
                                  AParamValues               : TStrings ;
                                  const ASaved               : TNPSavedData ) : boolean ;

    { Plugin methods - these are called from Netscape Navigator.        }
    { The parameters are more or less the same as the entry points from }
    { Navigator except that there's no Instance parameter since this is }
    { alread available in the Instance property and PChar's have been   }
    { converted to strings.                                             }
    function  SetWindow( Window   : PNPWindow ) : TNPError ; virtual ;
    function  NewStream( MimeType  : TNPMIMEType ;
                         Stream    : PNPStream ;
                         Seekable  : TNPBool ;
                         var SType : word ) : TNPError ; virtual ;
    function  DestroyStream( Stream   : PNPStream ;
                             Reason   : TNPReason ) : TNPError ; virtual ;
    function  WriteReady( Stream   : PNPStream ) : longint ; virtual ;
    function  Write( Stream   : PNPStream ;
                     Offset   : longint ;
                     Len      : longint ;
                     var Buffer ) : longint ; virtual ;
    procedure StreamAsFile( Stream   : PNPStream ;
                            FName    : string ) ; virtual ;
    procedure Print( PlatformPrint : PNPPrint ) ; virtual ;
    procedure URLNotify( URL      : string ;
                         Reason   : TNPReason ;
                         var NotifyData ) ; virtual ;
    function  GetJavaClass : JRef ; virtual ;

    function  GetScriptableObject : PNPObject ; virtual ;


    procedure Invalidate(); virtual ;
    function  HasMethod(name: TNPIdentifier): Boolean; virtual ;
    function  Invoke(name: TNPIdentifier; const args: PNPVariant; argCount: Cardinal; result_: PNPVariant): Boolean; virtual ;
    function  InvokeDefault(const args: PNPVariant; argCount: Cardinal; result_: PNPVariant): Boolean; virtual ;
    function  HasProperty(name: TNPIdentifier): Boolean; virtual ;
    function  GetProperty(name: TNPIdentifier; myresult: PNPVariant): Boolean; virtual ;
    function  SetProperty(name: TNPIdentifier; value: PNPVariant): Boolean; virtual ;
    function  RemoveProperty(name: TNPIdentifier): Boolean; virtual ;

    procedure SetException(const msg: string);

    function GetBrowserWindowObject: IBrowserObject;
    function GetBrowserWindowHandle: HWND;
    property BrowserType: TBrowserType read GetBrowserType;
  end ;
{$M-}


  TPluginClass = class of TPlugin ;



function  NPAllocate(npp: PNPP; aClass: PNPClass): PNPObject; cdecl;
procedure NPDeallocate(npobj: PNPObject); cdecl;
procedure NPInvalidate(npobj: PNPObject); cdecl;
function  NPHasMethod(npobj: PNPObject; name: TNPIdentifier): Boolean; cdecl;
function  NPInvoke(npobj: PNPObject; name: TNPIdentifier; const args: PNPVariant; argCount: Cardinal; result_: PNPVariant): Boolean; cdecl;
function  NPInvokeDefault(npobj: PNPObject; const args: PNPVariant; argCount: Cardinal; result_: PNPVariant): Boolean; cdecl;
function  NPHasProperty(npobj: PNPObject; name: TNPIdentifier): Boolean; cdecl;
function  NPGetProperty(npobj: PNPObject; name: TNPIdentifier; myresult: PNPVariant): Boolean; cdecl;
function  NPSetProperty(npobj: PNPObject; name: TNPIdentifier; value: PNPVariant): Boolean; cdecl;
function  NPRemoveProperty(npobj: PNPObject; name: TNPIdentifier): Boolean; cdecl;


procedure BOOLEAN_TO_NPVARIANT(value: Boolean; result: PNPVariant);
procedure INT32_TO_NPVARIANT(value: Integer; result: PNPVariant);
procedure DOUBLE_TO_NPVARIANT(value: Double; result: PNPVariant);
procedure VOID_TO_NPVARIANT(result: PNPVariant);
procedure STRING_TO_NPVARIANT(const str: String; result: PNPVariant);

function VariantToNPVariant(const v: OleVariant; result_: PNPVariant): Boolean;
function NPVariantToVariant(value: PNPVariant; Plugin: TPlugin = nil): Variant;
function VarAsObject(const v: OleVariant; AllowNilObject: boolean = False): IBrowserObject;

const
  cNPClass: TNPClass = (
    structVersion: NP_CLASS_STRUCT_VERSION_CTOR;
    allocate: NPAllocate;
    deallocate: NPDeallocate;
    invalidate: NPInvalidate;
    hasMethod: NPHasMethod;
    invoke: NPInvoke;
    invokeDefault: NPInvokeDefault;
    hasProperty: NPHasProperty;
    getProperty: NPGetProperty;
    setProperty: NPSetProperty;
    removeProperty: NPRemoveProperty;
    );

var
  NPP_DebugOut: procedure (const Msg: string);

implementation

uses
  TypInfo {$ifndef VER130} ,variants {$endif} {$ifdef VER130} ,UtfUtils {$endif};

const
  Separators = [ '|', ';' ] ;  { MIME type separators within the MIME types string }

type
  { TPluginClassInfo }
  { Used by the plugin framework to store information when a TPlugin class
    is registered to handle one or more MIME types. }
  TPluginClassInfo = class
  private
    FMimeTypes   : TStrings ;
    FPluginClass : TPluginClass ;
    FExtraInfo   : TObject ;
  protected
    procedure SetMimeTypes( const AMimeTypes : string ) ;
    procedure SetInfo( const AMimeTypes : string ;
                       APluginClass     : TPluginClass ;
                       AExtraInfo       : TObject ) ;
  public
    constructor Create( const AMimeTypes : string ;
                        APluginClass     : TPluginClass ;
                        AExtraInfo       : TObject ) ;
    destructor Destroy ; override ;
    property MimeTypes : TStrings read FMimeTypes ;
    property PluginClass : TPluginClass read FPluginClass ;
    property ExtraInfo : TObject read FExtraInfo ;
  end ;

  { TPlugins }
  { A TList descendant that has additional methods to handle TPluginClassInfo
    objects specifically and to find one given a set of MIME info and plugin
    parameters. Used to hold registered TPlugin classes. }
  TPlugins = class( TList )
  protected
    function  GetItem( Index : integer ) : TPluginClassInfo ;
  public
    destructor Destroy ; override ;
    function  Find( APluginType  : TNPMIMEType ;
                    AMode        : word ;
                    AParamNames  : TStrings ;
                    AParamValues : TStrings ;
                    const ASaved : TNPSavedData ) : TPluginClassInfo ;
    property  Items[ Index : integer ] : TPluginClassInfo read GetItem ; default ;
  end ;

  TBrowserObject = class(TObject, IBrowserObject)
  private
    FObject: PNPObject;
    FPlugIn: TPlugin;
    FRefCount: integer;
  protected
    function QueryInterface(const IID: TGUID; out Obj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;

    function Invoke(const MethodName: string; const Params: array of OleVariant): OleVariant;
    function InvokeDefault(const Params: array of OleVariant): OleVariant;
    function Evaluate(const Script: string): OleVariant;
    function GetProperty(const PropertyName: string): OleVariant;
    procedure SetProperty(const PropertyName: string; const Value: OleVariant);
    procedure RemoveProperty(const PropertyName: string);
    function HasProperty(const PropertyName: string): boolean;
    function HasMethod(const MethodName: string): boolean;
    function GetObject(const PropertyName: string): IBrowserObject;
  public
    constructor Create(PlugIn: TPlugin; obj: PNPObject);
  end;

var
  Plugins : TPlugins ;

{ Regular Netscape Plugin exports etc. }

var
  PluginFuncs     : PNPPluginFuncs ;
  NavigatorFuncs  : PNPNetscapeFuncs ;

function  NP_Initialize( pFuncs : PNPNetscapeFuncs ) : TNPError ; stdcall ;
var navMinorVers : integer ;
begin
  if pFuncs = NIL then begin
    Result := NPERR_INVALID_FUNCTABLE_ERROR ;
    exit ;
  end ;

  NavigatorFuncs := pFuncs ; { save it for future reference }

  { if the plugin's major ver level is lower than the Navigator's, }
  { then they are incompatible, and should return an error         }
  if Hi( pFuncs^.Version ) > NP_VERSION_MAJOR then begin
    Result := NPERR_INCOMPATIBLE_VERSION_ERROR ;
    exit ;
  end ;

  {  We have to defer these assignments until NavigatorFuncs is set }
  navMinorVers := NavigatorFuncs^.Version and $FF ;

  if navMinorVers >= NPVERS_HAS_NOTIFICATION then
    PluginFuncs^.URLNotify := NPP_URLNotify ;

  {$IFDEF WIN32}  { An ugly hack, because Win16 lags behind in Java }
      if navMinorVers >= NPVERS_HAS_LIVECONNECT then
  {$ELSE}
      if navMinorVers >= NPVERS_WIN16_HAS_LIVECONNECT then
  {$ENDIF}
        PluginFuncs^.javaClass := Private_GetJavaClass ;

  { NPP_Initialize is a standard (cross-platform) initialize function }
  result := NPP_Initialize ;
end ;

(* NP_GetEntryPoints
//
//	fills in the func table used by Navigator to call entry points in
//  plugin DLL.  Note that these entry points ensure that DS is loaded
//  by using the NP_LOADDS macro, when compiling for Win16
*)
function  NP_GetEntryPoints( pFuncs : PNPPluginFuncs ) : TNPError ; stdcall ;
begin
  { trap a NULL ptr }
  if pFuncs = NIL then begin
    result := NPERR_INVALID_FUNCTABLE_ERROR ;
    exit ;
  end ;

  { if the plugin's function table is smaller than the plugin expects,
    then they are incompatible, and should return an error }

  with pFuncs^ do begin
    Version       := ( NP_VERSION_MAJOR shl 8 ) or NP_VERSION_MINOR ;
    New           := NPP_New ;
    Destroy       := NPP_Destroy ;
    SetWindow     := NPP_SetWindow ;
    NewStream     := NPP_NewStream ;
    DestroyStream := NPP_DestroyStream ;
    StreamAsFile  := NPP_StreamAsFile ;
    WriteReady    := NPP_WriteReady ;
    Write         := NPP_Write ;
    Print         := NPP_Print ;
    JavaClass     := nil;
    GetValue      := NPP_GetValue ;
    SetValue      := NPP_SetValue ;
  end ;

  PluginFuncs := pFuncs ;

  result := NPERR_NO_ERROR;
end ;

(*	called immediately before the plugin DLL is unloaded.
//	This functio shuold check for some ref count on the dll to see if it is
//	unloadable or it needs to stay in memory.
*)
function  NP_Shutdown : TNPError ; stdcall ;
begin
  NPP_Shutdown ;
  NavigatorFuncs := NIL ;
  Result := NPERR_NO_ERROR ;
end ;

function  NPP_Initialize : TNPError ; cdecl ;
begin
  { should do any necessary initialization }
  Result := NPERR_NO_ERROR ;
end ;

procedure NPP_Shutdown ; cdecl ;
begin
  { should do any necessary tidy-up }
end ;

{ Given a Java class reference (thru NPP_GetJavaClass) inform JRT
  of this class existence }

function  Private_GetJavaClass : TJRIGlobalRef ; cdecl ;
begin
  Result := NIL ;
end ;

{ Plugin functions that are supplied to Netscape. }
{ You implement your plugin by filling in these functions... }

{*+++++++++++++++++++++++++++++++++++++++++++++++++
 * NPP_New:
 * Creates a new instance of a plug-in and returns an error value.
 *
 * NPP_New creates a new instance of your plug-in with MIME type specified
 * by pluginType. The parameter mode is NP_EMBED if the instance was created
 * by an EMBED tag, or NP_FULL if the instance was created by a separate file.
 * You can allocate any instance-specific private data in instance->pdata at this
 * time. The NPP pointer is valid until the instance is destroyed.
 +++++++++++++++++++++++++++++++++++++++++++++++++}
function  NPP_New( PluginType     : TNPMIMEType ;
                   Instance       : PNPP ;
                   Mode           : word ;
                   ArgC           : word ;
                   const Argn     : TPCharArray ;
                   const Argv     : TPCharArray ;
                   const Saved    : TNPSavedData ) : TNPError ; cdecl ;

  procedure CopyArgs( Count      : integer ;
                      const Args : TPCharArray ;
                      Strings    : TStrings ) ;
  var i : integer ;
  begin
    for i := 0 to Count - 1 do Strings.Add( StrPas( Args[ i ] ) ) ;
  end ;

var PluginClassInfo : TPluginClassInfo ;
    ArgNStrings     : TStrings ;
    ArgVStrings     : TStrings ;
begin
  Result := NPERR_GENERIC_ERROR ;
  try
    { move the arguments into TStrings objects }
    ArgVStrings := NIL ;
    ArgNStrings := TStringList.Create ;
    try
      ArgVStrings := TStringList.Create ;
      CopyArgs( ArgC, ArgN, ArgNStrings ) ;
      CopyArgs( ArgC, ArgV, ArgVStrings ) ;

      { find a plugin class to handle this instance }
      PluginClassInfo := Plugins.Find( PluginType, Mode, ArgNStrings, ArgVStrings, Saved ) ;
      if PluginClassInfo <> NIL then begin
        Instance.PData := PluginClassInfo.PluginClass.Create( Instance,
                                                              PluginClassInfo.ExtraInfo,
                                                              StrPas( PluginType ),
                                                              Mode,
                                                              ArgNStrings, ArgVStrings,
                                                              Saved ) ;
        Result := NPERR_NO_ERROR ;
      end ;
    finally
      ArgNStrings.Free ;
      ArgVStrings.Free ;
    end ;
  except
    { prevent any exception from leaking out of DLL }
    NPP_DebugOut('Error in NPP_New(): ' + Exception(ExceptObject).Message);
    Result:=NPERR_GENERIC_ERROR;
  end ;
end ;

{*+++++++++++++++++++++++++++++++++++++++++++++++++
 * NPP_Destroy:
 * Deletes a specific instance of a plug-in and returns an error value.

 * NPP_Destroy is called when a plug-in instance is deleted, typically because the
 * user has left the page containing the instance, closed the window, or quit the
 * application. You should delete any private instance-specific information stored
 * in instance->pdata. If the instance being deleted is the last instance created
 * by your plug-in, NPP_Shutdown will subsequently be called, where you can
 * delete any data allocated in NPP_Initialize to be shared by all your plug-in's
 * instances. Note that you should not perform any graphics operations in
 * NPP_Destroy as the instance's window is no longer guaranteed to be valid.
 +++++++++++++++++++++++++++++++++++++++++++++++++}
function  NPP_Destroy( Instance : PNPP ;
                       var Save       : PNPSavedData ) : TNPError ; cdecl ;
begin
  Result := NPERR_GENERIC_ERROR ;
  try
    if ( Instance <> NIL ) and ( Instance.PData <> NIL ) then
      FreeAndNil(TPlugin( Instance.PData ));
    Result := NPERR_NO_ERROR ;
  except
    { prevent any exception from leaking out of DLL }
  end ;
end ;

{+++++++++++++++++++++++++++++++++++++++++++++++++
 * NPP_SetWindow:
 * Sets the window in which a plug-in draws, and returns an error value.
 *
 * NPP_SetWindow informs the plug-in instance specified by instance of the
 * the window denoted by window in which the instance draws. This NPWindow
 * pointer is valid for the life of the instance, or until NPP_SetWindow is called
 * again with a different value. Subsequent calls to NPP_SetWindow for a given
 * instance typically indicate that the window has been resized. If either window
 * or window->window are NULL, the plug-in must not perform any additional
 * graphics operations on the window and should free any resources associated
 * with the window.
 +++++++++++++++++++++++++++++++++++++++++++++++++}
function  NPP_SetWindow( Instance : PNPP ;
                         Window   : PNPWindow ) : TNPError ; cdecl ;
begin
  Result := NPERR_GENERIC_ERROR ;
  try
    if ( Instance <> NIL ) and ( Instance.PData <> NIL ) then
      Result := TPlugin( Instance.PData ).SetWindow( Window ) ;
  except
    { prevent any exception from leaking out of DLL }
    Result:=NPERR_GENERIC_ERROR;
  end ;
end ;

{*+++++++++++++++++++++++++++++++++++++++++++++++++
 * NPP_NewStream:
 * Notifies an instance of a new data stream and returns an error value.
 *
 * NPP_NewStream notifies the instance denoted by instance of the creation of
 * a new stream specifed by stream. The NPStream* pointer is valid until the
 * stream is destroyed. The MIME type of the stream is provided by the
 * parameter type.
 +++++++++++++++++++++++++++++++++++++++++++++++++}
function  NPP_NewStream( Instance  : PNPP ;
                         MimeType  : TNPMIMEType ;
                         Stream    : PNPStream ;
                         Seekable  : TNPBool ;
                         var SType : word ) : TNPError ; cdecl ;
begin
  Result := NPERR_GENERIC_ERROR ;
  try
    if ( Instance <> NIL ) and ( Instance.PData <> NIL ) then
      Result := TPlugin( Instance.PData ).NewStream( MimeType, Stream, Seekable, SType ) ;
  except
    { prevent any exception from leaking out of DLL }
    Result:=NPERR_GENERIC_ERROR;
  end ;
end ;

{*+++++++++++++++++++++++++++++++++++++++++++++++++
 * NPP_DestroyStream:
 * Indicates the closure and deletion of a stream, and returns an error value.
 *
 * The NPP_DestroyStream function is called when the stream identified by
 * stream for the plug-in instance denoted by instance will be destroyed. You
 * should delete any private data allocated in stream->pdata at this time.
 +++++++++++++++++++++++++++++++++++++++++++++++++}
function  NPP_DestroyStream( Instance : PNPP ;
                             Stream   : PNPStream ;
                             Reason         : TNPReason ) : TNPError ; cdecl ;
begin
  Result := NPERR_GENERIC_ERROR ;
  try
    if ( Instance <> NIL ) and ( Instance.PData <> NIL ) then
      Result := TPlugin( Instance.PData ).DestroyStream( Stream, Reason ) ;
  except
    { prevent any exception from leaking out of DLL }
    Result:=NPERR_GENERIC_ERROR;
  end ;
end ;

{* PLUGIN DEVELOPERS:
 *	These next 2 functions are directly relevant in a plug-in which
 *	handles the data in a streaming manner. If you want zero bytes
 *	because no buffer space is YET available, return 0. As long as
 *	the stream has not been written to the plugin, Navigator will
 *	continue trying to send bytes.  If the plugin doesn't want them,
 *	just return some large number from NPP_WriteReady(), and
 *	ignore them in NPP_Write().  For a NP_ASFILE stream, they are
 *	still called but can safely be ignored using this strategy.
 *}

const STREAMBUFSIZE : longint = $0FFFFFFF ; {* If we are reading from a file in NPAsFile
				             * mode so we can take any size stream in our
                                             * write call (since we ignore it) }

{*+++++++++++++++++++++++++++++++++++++++++++++++++
 * NPP_WriteReady:
 * Returns the maximum number of bytes that an instance is prepared to accept
 * from the stream.
 *
 * NPP_WriteReady determines the maximum number of bytes that the
 * instance will consume from the stream in a subsequent call NPP_Write. This
 * function allows Netscape to only send as much data to the instance as the
 * instance is capable of handling at a time, allowing more efficient use of
 * resources within both Netscape and the plug-in.
 +++++++++++++++++++++++++++++++++++++++++++++++++}
function  NPP_WriteReady( Instance : PNPP ;
                          Stream   : PNPStream ) : longint ; cdecl ;
begin
  Result := NPERR_GENERIC_ERROR ;
  try
    if ( Instance <> NIL ) and ( Instance.PData <> NIL ) then
      Result := TPlugin( Instance.PData ).WriteReady( Stream ) ;
  except
    { prevent any exception from leaking out of DLL }
    Result:=NPERR_GENERIC_ERROR;
  end ;
end ;

{*+++++++++++++++++++++++++++++++++++++++++++++++++
 * NPP_Write:
 * Delivers data from a stream and returns the number of bytes written.
 *
 * NPP_Write is called after a call to NPP_NewStream in which the plug-in
 * requested a normal-mode stream, in which the data in the stream is delivered
 * progressively over a series of calls to NPP_WriteReady and NPP_Write. The
 * function delivers a buffer buf of len bytes of data from the stream identified
 * by stream to the instance. The parameter offset is the logical position of
 * buf from the beginning of the data in the stream.
 *
 * The function returns the number of bytes written (consumed by the instance).
 * A negative return value causes an error on the stream, which will
 * subsequently be destroyed via a call to NPP_DestroyStream.
 *
 * Note that a plug-in must consume at least as many bytes as it indicated in the
 * preceeding NPP_WriteReady call. All data consumed must be either processed
 * immediately or copied to memory allocated by the plug-in: the buf parameter
 * is not persistent.
 +++++++++++++++++++++++++++++++++++++++++++++++++}
function  NPP_Write( Instance : PNPP ;
                     Stream   : PNPStream ;
                     Offset         : longint ;
                     Len            : longint ;
                     var Buffer ) : longint ; cdecl ;
begin
  Result := NPERR_GENERIC_ERROR ;
  try
    if ( Instance <> NIL ) and ( Instance.PData <> NIL ) then
      Result := TPlugin( Instance.PData ).Write( Stream, Offset, Len, Buffer ) ;
  except
    { prevent any exception from leaking out of DLL }
    Result:=NPERR_GENERIC_ERROR;
  end ;
end ;

{*+++++++++++++++++++++++++++++++++++++++++++++++++
 * NPP_StreamAsFile:
 * Provides a local file name for the data from a stream.
 *
 * NPP_StreamAsFile provides the instance with a full path to a local file,
 * identified by fname, for the stream specified by stream. NPP_StreamAsFile is
 * called as a result of the plug-in requesting mode NP_ASFILEONLY or
 * NP_ASFILE in a previous call to NPP_NewStream. If an error occurs while
 * retrieving the data or writing the file, fname may be NULL.
 +++++++++++++++++++++++++++++++++++++++++++++++++}
procedure  NPP_StreamAsFile( Instance : PNPP ;
                             Stream   : PNPStream ;
                             FName          : PChar ) ; cdecl ;
begin
  try
    if ( Instance <> NIL ) and ( Instance.PData <> NIL ) then
      TPlugin( Instance.PData ).StreamAsFile( Stream, FName ) ;
  except
    { prevent any exception from leaking out of DLL }
  end ;
end ;

{*+++++++++++++++++++++++++++++++++++++++++++++++++
 * NPP_Print:
 +++++++++++++++++++++++++++++++++++++++++++++++++}
procedure  NPP_Print( Instance : PNPP ;
                      PlatformPrint : PNPPrint ) ; cdecl ;
begin
  try
    if ( Instance <> NIL ) and ( Instance.PData <> NIL ) then
      TPlugin( Instance.PData ).Print( PlatformPrint ) ;
  except
    { prevent any exception from leaking out of DLL }
  end ;
end ;

{*+++++++++++++++++++++++++++++++++++++++++++++++++
 * NPP_HandleEvent:
 * Mac-only, but stub must be present for Windows
 * Delivers a platform-specific event to the instance.
 *
 * On the Macintosh, event is a pointer to a standard Macintosh EventRecord.
 * All standard event types are passed to the instance as appropriate. In general,
 * return TRUE if you handle the event and FALSE if you ignore the event.
 +++++++++++++++++++++++++++++++++++++++++++++++++}
function  NPP_HandleEvent( Instance : PNPP ;
                           var Event ) : smallint ; cdecl ;
begin
  Result := NPERR_NO_ERROR ;
end ;

{*+++++++++++++++++++++++++++++++++++++++++++++++++
 * NPP_URLNotify:
 * Notifies the instance of the completion of a URL request.
 *
 * NPP_URLNotify is called when Netscape completes a NPN_GetURLNotify or
 * NPN_PostURLNotify request, to inform the plug-in that the request,
 * identified by url, has completed for the reason specified by reason. The most
 * common reason code is NPRES_DONE, indicating simply that the request
 * completed normally. Other possible reason codes are NPRES_USER_BREAK,
 * indicating that the request was halted due to a user action (for example,
 * clicking the "Stop" button), and NPRES_NETWORK_ERR, indicating that the
 * request could not be completed (for example, because the URL could not be
 * found). The complete list of reason codes is found in npapi.h.
 *
 * The parameter notifyData is the same plug-in-private value passed as an
 * argument to the corresponding NPN_GetURLNotify or NPN_PostURLNotify
 * call, and can be used by your plug-in to uniquely identify the request.
 +++++++++++++++++++++++++++++++++++++++++++++++++}
procedure  NPP_URLNotify( Instance       : PNPP ;
                          URL            : PChar ;
                          Reason         : TNPReason ;
                          var NotifyData ) ; cdecl ;
begin
  try
    if ( Instance <> NIL ) and ( Instance.PData <> NIL ) then
      TPlugin( Instance.PData ).URLNotify( StrPas( URL ), Reason, NotifyData ) ;
  except
    { prevent any exception from leaking out of DLL }
  end ;
end ;

{*+++++++++++++++++++++++++++++++++++++++++++++++++
 * NPP_GetJavaClass:
 * New in Netscape Navigator 3.0.
 *
 * NPP_GetJavaClass is called during initialization to ask your plugin
 * what its associated Java class is. If you don't have one, just return
 * NULL. Otherwise, use the javah-generated "use_" function to both
 * initialize your class and return it. If you can't find your class, an
 * error will be signalled by "use_" and will cause the Navigator to
 * complain to the user.
 +++++++++++++++++++++++++++++++++++++++++++++++++}
function  NPP_GetJavaClass : JRef ; cdecl ;
begin
  Result := NIL ;
end ;

function  NPP_GetValue(instance: PNPP;
                           variable: TNPPVariable;
                           value: Pointer): TNPError; cdecl;
begin
  if instance = nil then
  begin
    Result := NPERR_INVALID_INSTANCE_ERROR;
    Exit;
  end;

  Result := NPERR_NO_ERROR;

  case variable of
    NPPVpluginScriptableNPObject:
      try
        if ( instance <> NIL ) and ( instance.PData <> NIL ) then
           PPNPObject(value)^ := TPlugin( Instance.PData ).GetScriptableObject;
      except
        { prevent any exception from leaking out of DLL }
        Result:=NPERR_GENERIC_ERROR;
      end ;
    else
      Result := NPERR_GENERIC_ERROR;
  end;
end;

  // Comment from Mozilla src: shouldn't NPP_SetValue() take an NPPVariable and not an NPNVariable?
function  NPP_SetValue(instance: PNPP;
                           variable: TNPNVariable;
                           value: Pointer): TNPError; cdecl;
begin
  if instance = nil then
  begin
    Result := NPERR_INVALID_INSTANCE_ERROR;
    Exit;
  end;

  Result := NPERR_NO_ERROR;
end;

{ Netscape Navigator functions }

procedure  NPN_Version( var PluginMajor : integer ;
                        var PluginMinor : integer ;
                        var NetscapeMajor : integer ;
                        var NetscapeMinor : integer ) ;
begin
  PluginMajor := NP_VERSION_MAJOR ;
  PluginMinor := NP_VERSION_MINOR ;
  { Netscape C sample doesn't return anything in NetscapeMajor and NetscapeMinor! }
  { The following is commented out in the samples. }
  { NetscapeMajor := Hi( NavigatorFuncs.Version ) ; }
  { NetscapeMinor := Lo( NavigatorFuncs.Version ) ; }
end ;

function  NPN_GetURLNotify( Instance : PNPP ;
                            URL      : PChar ;
                            Target   : PChar ;
                            var NotifyData ) : TNPError ;
begin
  if ( NavigatorFuncs.Version and $FF >= NPVERS_HAS_NOTIFICATION ) then
    Result := NavigatorFuncs.GetURLNotify( Instance, URL, Target, NotifyData ) else
    Result := NPERR_INCOMPATIBLE_VERSION_ERROR ;
end ;

function  NPN_GetURL( Instance : PNPP ;
                      URL      : PChar ;
                      Target   : PChar ) : TNPError ;
begin
  Result := NavigatorFuncs.GetURL( Instance, URL, Target ) ;
end ;

function  NPN_PostURLNotify( Instance : PNPP ;
                             URL      : PChar ;
                             Target   : PChar ;
                             Len      : longint ;
                             var Buf ;
                             IsFile   : TNPBool ;
                             var NotifyData ) : TNPError ;
begin
  if ( NavigatorFuncs.Version and $FF >= NPVERS_HAS_NOTIFICATION ) then
    Result := NavigatorFuncs.PostURLNotify( Instance, URL, Target,
                                               Len, Buf, IsFile, NotifyData )
  else
    Result := NPERR_INCOMPATIBLE_VERSION_ERROR ;
end ;

function  NPN_PostURL( Instance : PNPP ;
                       URL      : PChar ;
                       Window   : PChar ;
                       Len      : longint ;
                       const Buf ;
                       IsFile   : TNPBool ) : TNPError ;
begin
  Result := NavigatorFuncs.PostURL( Instance, URL, Window, Len, Buf, IsFile ) ;
end ;

{  Requests that a number of bytes be provided on a stream.  Typically
   this would be used if a stream was in "pull" mode.  An optional
   position can be provided for streams which are seekable.
}
function  NPN_RequestRead( Stream          : PNPStream;
                           const RangeList : TNPByteRange ) : TNPError ;
begin
  Result := NavigatorFuncs.RequestRead( Stream, RangeList ) ;
end ;

{  Creates a new stream of data from the plug-in to be interpreted
   by Netscape in the current window.
}
function  NPN_NewStream( Instance : PNPP ;
                         MimeType : TNPMIMEType ;
                         Target   : PChar ;
                         var Stream : PNPStream ) : TNPError ;
begin
  if ( NavigatorFuncs.Version and $FF >= NPVERS_HAS_STREAMOUTPUT ) then
    Result := NavigatorFuncs.NewStream( Instance, MimeType, Target, Stream ) else
    Result := NPERR_INCOMPATIBLE_VERSION_ERROR ;
end ;

{  Provides len bytes of data.
}
function  NPN_Write( Instance : PNPP ;
                     Stream   : PNPStream ;
                     Len      : longint ;
                     var Buffer ) : longint ;
begin
  if ( NavigatorFuncs.Version and $FF >= NPVERS_HAS_STREAMOUTPUT ) then
    Result := NavigatorFuncs.Write( Instance, Stream, Len, Buffer ) else
    Result := -1 ;
end ;

{ Closes a stream object.
  reason indicates why the stream was closed.
}
function  NPN_DestroyStream( Instance : PNPP ;
                             Stream   : PNPStream ;
                             Reason   : TNPReason ) : TNPError ;
begin
  if ( NavigatorFuncs.Version and $FF >= NPVERS_HAS_STREAMOUTPUT ) then
    Result := NavigatorFuncs.DestroyStream( Instance, Stream, Reason ) else
    Result := NPERR_INCOMPATIBLE_VERSION_ERROR ;
end ;

{  Provides a text status message in the Netscape client user interface
}
procedure NPN_Status( Instance : PNPP ;
                      Message  : PChar ) ;
begin
  NavigatorFuncs.Status( Instance, Message ) ;
end ;

{  returns the user agent string of Navigator, which contains version info
}
function  NPN_UserAgent( Instance : PNPP ) : PChar ;
begin
  Result := NavigatorFuncs.UserAgent( Instance ) ;
end ;

{  allocates memory from the Navigator's memory space.  Necessary so that
   saved instance data may be freed by Navigator when exiting.
}

function  NPN_MemAlloc( Size : longint ) : pointer ;
begin
  Result := NavigatorFuncs.MemAlloc( Size ) ;
end ;

{  reciprocal of MemAlloc() above
}
procedure NPN_MemFree( Ptr : pointer ) ;
begin
  NavigatorFuncs.MemFree( Ptr ) ;
end ;

{ private function to Netscape.  do not use! (so why's it here??? -Mike)
}
procedure NPN_ReloadPlugins( ReloadPages : TNPBool ) ;
begin
  NavigatorFuncs.ReloadPlugins( ReloadPages ) ;
end ;

function  NPN_GetJavaEnv : PJRIEnv ;
begin
  Result := NavigatorFuncs.GetJavaEnv ;
end ;

function  NPN_GetJavaPeer( Instance : PNPP ) : TJRef ;
begin
  Result := NavigatorFuncs.GetJavaPeer( Instance ) ;
end;

function  NPN_GetStringIdentifier(name: PNPUTF8): TNPIdentifier;
begin
  Result := NavigatorFuncs.GetStringIdentifier( name ) ;
end;

function  NPN_UTF8FromIdentifier(identifier: TNPIdentifier): PNPUTF8;
begin
  Result := NavigatorFuncs.UTF8FromIdentifier(identifier);
end;

function  NPN_IntFromIdentifier(identifier: TNPIdentifier): longint;
begin
  Result := NavigatorFuncs.IntFromIdentifier(identifier);
end;

function  NPN_CreateObject(npp: PNPP; aClass: PNPClass): PNPObject;
begin
  Result := NavigatorFuncs.CreateObject(npp, aClass);
end;

function  NPN_RetainObject(npobj: PNPObject): PNPObject;
begin
  Result := NavigatorFuncs.RetainObject(npobj);
end;

procedure NPN_ReleaseObject(npobj: PNPObject);
begin
  NavigatorFuncs.ReleaseObject(npobj);
end;

procedure NPN_SetException(npobj: PNPObject; msg: PNPUTF8);
begin
  NavigatorFuncs.SetException(npobj, msg);
end;

function  NPN_GetValue(instance: PNPP; variable: TNPNVariable; value: Pointer): TNPError;
begin
  Result:=NavigatorFuncs.GetValue(instance, variable, value);
end;

function  NPN_SetValue(instance: PNPP; variable: TNPPVariable; value: Pointer): TNPError;
begin
  Result:=NavigatorFuncs.SetValue(instance, variable, value);
end;

procedure NPN_ReleaseVariantValue(variant: PNPVariant);
begin
  NavigatorFuncs.ReleaseVariantValue(variant);
end;

function  NPAllocate(npp: PNPP; aClass: PNPClass): PNPObject;
begin
  try
    GetMem(Result, SizeOf(TNPObject));
    FillChar(Result^, SizeOf(TNPObject), 0);
    Result.plugin := npp.PData;
  except
    { prevent any exception from leaking out of DLL }
    Result:=nil;
  end;
end;

procedure NPDeallocate(npobj: PNPObject);
begin
  try
    if npobj <> nil then begin
      if npobj.plugin <> nil then
        TPlugin(npobj.plugin).m_pScriptableObject:=nil;
      FreeMem(npobj);
    end;
  except
    { prevent any exception from leaking out of DLL }
  end;
end;

procedure NPInvalidate(npobj: PNPObject);
begin
  try
    if npobj.plugin <> nil then
      TPlugin(npobj.plugin).Invalidate;
  except
    { prevent any exception from leaking out of DLL }
  end;
end;

function  NPHasMethod(npobj: PNPObject; name: TNPIdentifier): Boolean;
begin
  Result:=False;
  try
    if npobj.plugin <> nil then
      Result := TPlugin(npobj.plugin).HasMethod(name);
  except
    { prevent any exception from leaking out of DLL }
  end;
end;

function  NPInvoke(npobj: PNPObject; name: TNPIdentifier; const args: PNPVariant; argCount: Cardinal; result_: PNPVariant): Boolean;
begin
  Result:=False;
  try
    if npobj.plugin <> nil then
      Result := TPlugin(npobj.plugin).Invoke(name, args, argCount, result_);
  except
    on E: Exception do begin
      try
        TPlugin(npobj.plugin).SetException(E.Message);
        Result:=True;
      except
        { prevent any exception from leaking out of DLL }
      end;
    end;
  end;
end;

function  NPInvokeDefault(npobj: PNPObject; const args: PNPVariant; argCount: Cardinal; result_: PNPVariant): Boolean; cdecl;
begin
  Result:=False;
  try
    if npobj.plugin <> nil then
      Result := TPlugin(npobj.plugin).InvokeDefault(args, argCount, result_);
  except
    on E: Exception do begin
      try
        TPlugin(npobj.plugin).SetException(E.Message);
        Result:=True;
      except
        { prevent any exception from leaking out of DLL }
      end;
    end;
  end;
end;

function  NPHasProperty(npobj: PNPObject; name: TNPIdentifier): Boolean; cdecl;
begin
  Result:=False;
  try
    if npobj.plugin <> nil then
      Result := TPlugin(npobj.plugin).HasProperty(name);
  except
    { prevent any exception from leaking out of DLL }
  end;
end;

function  NPGetProperty(npobj: PNPObject; name: TNPIdentifier; myresult: PNPVariant): Boolean; cdecl;
begin
  Result:=False;
  try
    if npobj.plugin <> nil then
      Result := TPlugin(npobj.plugin).GetProperty(name, myresult);
  except
    on E: Exception do begin
      try
        TPlugin(npobj.plugin).SetException(E.Message);
        Result:=True;
      except
        { prevent any exception from leaking out of DLL }
      end;
    end;
  end;
end;

function  NPSetProperty(npobj: PNPObject; name: TNPIdentifier; value: PNPVariant): Boolean; cdecl;
begin
  Result:=False;
  try
    if npobj.plugin <> nil then
      Result := TPlugin(npobj.plugin).SetProperty(name, value);
  except
    on E: Exception do begin
      try
        TPlugin(npobj.plugin).SetException(E.Message);
        Result:=True;
      except
        { prevent any exception from leaking out of DLL }
      end;
    end;
  end;
end;

function  NPRemoveProperty(npobj: PNPObject; name: TNPIdentifier): Boolean; cdecl;
begin
  Result:=False;
  try
    if npobj.plugin <> nil then
      Result := TPlugin(npobj.plugin).RemoveProperty(name);
  except
    on E: Exception do begin
      try
        TPlugin(npobj.plugin).SetException(E.Message);
        Result:=True;
      except
        { prevent any exception from leaking out of DLL }
      end;
    end;
  end;
end;

procedure INT32_TO_NPVARIANT(value: Integer; result: PNPVariant);
begin
  result._type := NPVARIANTTYPE_INT32;
  result.value.intValue := value;
end;

procedure DOUBLE_TO_NPVARIANT(value: Double; result: PNPVariant);
begin
  result._type := NPVARIANTTYPE_DOUBLE;
  result.value.doubleValue := value;
end;

procedure BOOLEAN_TO_NPVARIANT(value: Boolean; result: PNPVariant);
begin
  result._type := NPVARIANTTYPE_BOOL;
  result.value.boolValue := value;
end;

procedure VOID_TO_NPVARIANT(result: PNPVariant);
begin
  result._type := NPVARIANTTYPE_VOID;
  result.value.objectValue := nil;
end;

procedure STRING_TO_NPVARIANT(const str: String; result: PNPVariant);
var
  s: AnsiString;
begin
  s:=UTF8Encode(str);
  result._type := NPVARIANTTYPE_STRING;
  result.value.stringValue.utf8characters := NPN_MemAlloc(length( s ) +1);
  StrPCopy( result.value.stringValue.utf8characters, s );
  result.value.stringValue.utf8length := Length(s);
end;

function GetImplementingObject(const I: IUnknown): TObject;
const   
  AddByte = $04244483;  
  AddLong = $04244481;  
type   
  PAdjustSelfThunk = ^TAdjustSelfThunk;   
  TAdjustSelfThunk = packed record     
    case AddInstruction: longint of       
      AddByte : (AdjustmentByte: shortint);       
      AddLong : (AdjustmentLong: longint);   
    end;   
  PInterfaceMT = ^TInterfaceMT;   
  TInterfaceMT = packed record     
    QueryInterfaceThunk: PAdjustSelfThunk;   
  end;   
  TInterfaceRef = ^PInterfaceMT; 
var   
  QueryInterfaceThunk: PAdjustSelfThunk; 
begin   
  Result := Pointer(I);   
  if Assigned(Result) then     
    try       
      QueryInterfaceThunk := TInterfaceRef(I)^.QueryInterfaceThunk;       
      case QueryInterfaceThunk.AddInstruction of         
        AddByte: Inc(PChar(Result), QueryInterfaceThunk.AdjustmentByte);         
        AddLong: Inc(PChar(Result), QueryInterfaceThunk.AdjustmentLong);         
      else     
        Result := nil;       
      end;     
    except       
      Result := nil;     
    end; 
end;

function VariantToNPVariant(const v: OleVariant; result_: PNPVariant): Boolean;
begin
  Result := True;
  case VarType(v) of
    varEmpty: VOID_TO_NPVARIANT(result_);
    varNull: result_._type:=NPVARIANTTYPE_NULL;
    varBoolean: BOOLEAN_TO_NPVARIANT(v, result_);
    varInteger, varByte, varSmallint: INT32_TO_NPVARIANT(v, result_);
    varSingle, varDouble: DOUBLE_TO_NPVARIANT(v, result_);
    varString, varOleStr: STRING_TO_NPVARIANT(v, result_);
    varUnknown:
      begin
        result_._type:=NPVARIANTTYPE_OBJECT;
        result_.value.objectValue:=TBrowserObject(GetImplementingObject(VarAsObject(v))).FObject;
        NPN_RetainObject(result_.value.objectValue);
      end
    else
      raise Exception.CreateFmt('Unsupported variant type: %d', [VarType(v)]);
  end;
end;

function NPStringToString(const input: TNPString) : string; overload;
var
  sOut: AnsiString;
begin
  SetString(sOut, input.utf8characters, input.utf8length);
  Result:=UTF8Decode(sOut);
end;

function NPVariantToVariant(value: PNPVariant; Plugin: TPlugin): Variant;
begin
  case value._type of
    NPVARIANTTYPE_VOID: Result := Unassigned;
    NPVARIANTTYPE_NULL: Result := Null;
    NPVARIANTTYPE_BOOL: Result := value.value.boolValue;
    NPVARIANTTYPE_INT32: Result := value.value.intValue;
    NPVARIANTTYPE_DOUBLE: Result := value.value.doubleValue;
    NPVARIANTTYPE_STRING: Result := NPStringToString(value.value.stringValue);
    NPVARIANTTYPE_OBJECT:
      begin
        if Plugin = nil then
          raise Exception.Create('Failed to create a browser object. Plugin parameter was not specified.');
        Result := IBrowserObject(TBrowserObject.Create(Plugin, value.value.objectValue));
      end;
    else
      raise Exception.CreateFmt('Unsupported NPvariant type: %d', [value._type]);
  end;
end;

function VarAsObject(const v: OleVariant; AllowNilObject: boolean): IBrowserObject;
begin
  if VarType(v) in [varEmpty, varNull] then begin
    if AllowNilObject then
      Result:=nil
    else
      raise Exception.Create('Can''t create an object from a NULL variant.');
  end                                                                    
  else
    if VarType(v) = varUnknown then
      Result:=IBrowserObject(TVarData(v).VUnknown)
    else
      raise Exception.Create('Variant is not an object.');
end;

{ TPluginClassInfo }

constructor TPluginClassInfo.Create( const AMimeTypes : string ;
                                     APluginClass     : TPluginClass ;
                                     AExtraInfo       : TObject ) ;
begin
  inherited Create ;
  FMimeTypes := TStringList.Create ;
  SetInfo( AMimeTypes, APluginClass, AExtraInfo ) ;
end ;

destructor TPluginClassInfo.Destroy ;
begin
  FExtraInfo.Free ;
  FMimeTypes.Free ;
  inherited Destroy ;
end ;

procedure TPluginClassInfo.SetMimeTypes( const AMimeTypes : string ) ;
var i, Start : integer ;
begin
  { Split the MIME types up into a TStrings object for easier processing later }
  { Individual MIME strings can be separated within the whole string either by }
  { pipe characters ('|') or semi-colons.                                      }
  i := 1 ;
  while i <= Length( AMimeTypes ) do begin
    while ( i <= Length( AMimeTypes ) ) and
          ( AMimeTypes[ i ] in Separators ) do
      inc( i ) ;
    Start := i ;
    while ( i <= Length( AMimeTypes ) ) and
          not ( AMimeTypes[ i ] in Separators ) do inc( i ) ;
    if i >= Start then
      FMimeTypes.Add( Copy( AMimeTypes, Start, i - Start ) ) else
      FMimeTypes.Add( '' ) ;
  end ;
end ;

procedure TPluginClassInfo.SetInfo( const AMimeTypes : string ;
                                    APluginClass     : TPluginClass ;
                                    AExtraInfo       : TObject ) ;
begin
  { set the plugin info for this plugin class }
  if APluginClass = NIL then
    Raise Exception.Create( 'NIL plugin class not allowed' ) ;
  SetMimeTypes( AMimeTypes ) ;
  FPluginClass := APluginClass ;
  if FExtraInfo <> AExtraInfo then begin
    FExtraInfo.Free ;
    FExtraInfo := AExtraInfo ;
  end ;
end ;

{ TPlugins }

destructor TPlugins.Destroy ;
var i : integer ;
begin
  for i := 0 to Count - 1 do
    Items[ i ].Free ;
  inherited;  
end;

function  TPlugins.GetItem( Index : integer ) : TPluginClassInfo ;
begin
  Result := TPluginClassInfo( inherited Items[ Index ] ) ;
end ;

function  TPlugins.Find( APluginType  : TNPMIMEType ;
                         AMode        : word ;
                         AParamNames  : TStrings ;
                         AParamValues : TStrings ;
                         const ASaved : TNPSavedData ) : TPluginClassInfo ;
var i : integer ;
begin
  { find a plugin class that wants to handle this plugin type }
  for i := Count - 1 downto 0 do begin
    Result := Items[ i ] ;
    //Write2EventLog('FlexKbd', Result.MimeTypes);
    if Result.PluginClass.IsInterested( Result.MimeTypes, StrPas( APluginType ),
                                        AMode, AParamNames, AParamValues, ASaved ) then
      exit ;
  end ;
  Result := NIL ;
end ;

{ TPlugin }

constructor TPlugin.Create( AInstance : PNPP ;
                            AExtraInfo : TObject ;
                            const APluginType : string ;
                            AMode             : word ;
                            AParamNames       : TStrings ;
                            AParamValues      : TStrings ;
                            const ASaved      : TNPSavedData ) ;
begin
  inherited Create ;
  FBrowserType := btInvalid;
  FInstance := AInstance ;
  FExtraInfo := AExtraInfo ;
  FPluginType := PluginType ;
  FParamNames:=TStringList.Create;
  FParamNames.Assign(AParamNames);
  FParamValues:=TStringList.Create;
  FParamValues.Assign(AParamValues);
end ;

destructor TPlugin.Destroy ;
begin
  { free the parameter strings of which we took ownership }
  FParamNames.Free;
  FParamValues.Free;
  if m_pScriptableObject <> nil then begin
    m_pScriptableObject.plugin:=nil;
    NPN_ReleaseObject(m_pScriptableObject);
  end;
  inherited Destroy ;
end ;


class procedure TPlugin.Register( const MimeTypes : string ;
                                  ExtraInfo       : TObject ) ;
var Info  : TPluginClassInfo ;
begin
  { Register this plugin class with the plugin framework }
  Info := TPluginClassInfo.Create( MimeTypes, Self, ExtraInfo ) ;
  try
    Plugins.Add( Info ) ;
  except
    Info.Free ;
    Raise ;
  end ;
end ;

class function  TPlugin.IsInterested( const ARegisteredMimeTypes : TStrings ;
                                      const APluginType          : string ;
                                      AMode                      : word ;
                                      AParamNames                : TStrings ;
                                      AParamValues               : TStrings ;
                                      const ASaved               : TNPSavedData ) : boolean ;
var i     : integer ;
    AType : string ;
begin
  { Return true if this class is interested in the passed MIME type and parameters. }
  { Default is that class is interested if the requested MIME type is
    in the list of registered MIME types or there are no registered MIME type,
    i.e. an empty string was passed when the class was registered with the framework. }
  Result := true ;

  { if no specific strings were registered, then we are interested in all types }
  if ARegisteredMimeTypes.Count = 0 then exit ;

  { check type with registered types - again,
    an empty string means interested in all }
  for i := 0 to ARegisteredMimeTypes.Count - 1 do begin
    AType := ARegisteredMimeTypes[ i ] ;
    if ( AType = '' ) or ( CompareText( AType, APluginType ) = 0 ) then
      exit ;
  end ;
  Result := false ;
end ;

procedure TPlugin.WindowHandleChanging ;
begin
  { notification method - override if necessary }
end ;

procedure TPlugin.WindowHandleChanged ;
begin
  { notification method - override if necessary }
end ;

procedure TPlugin.WindowChanged ;
begin
  { Navigator has said that the window has changed size or needs repainted
    but the window handle is still the same.
    Notification method - override if necessary }
end ;

function  TPlugin.SetWindow( Window : PNPWindow ) : TNPError ;
var ANewHandle : HWnd ;
begin
  { Netscape has done something with the plugin window, i.e. created one,
    resized one or it simply needs painting. If there's a new window handle,
    call WindowHandleChanging then WindowHandleChanged. In all cases call
    WindowChanged which can be seen as a Paint call if there is no other
    painting mechanism in place. }
  if Window <> NIL then ANewHandle := Window.Window else
    ANewHandle := 0 ;
  if FWindowHandle <> ANewHandle then begin
    WindowHandleChanging ;
    FWindowHandle := ANewHandle ;
    WindowHandleChanged ;
  end ;
  WindowChanged ;
  Result := NPERR_NO_ERROR ;
end ;

function  TPlugin.NewStream( MimeType  : TNPMIMEType ;
                             Stream    : PNPStream ;
                             Seekable  : TNPBool ;
                             var SType : word ) : TNPError ;
begin
  Result := NPERR_NO_ERROR ;
end ;

function  TPlugin.DestroyStream( Stream : PNPStream ;
                                         Reason : TNPReason ) : TNPError ;
begin
  Result := NPERR_NO_ERROR ;
end ;

function  TPlugin.WriteReady( Stream   : PNPStream ) : longint ;
begin
  Result := NPERR_NO_ERROR ;
end ;

function  TPlugin.Write( Stream   : PNPStream ;
                         Offset   : longint ;
                         Len      : longint ;
                         var Buffer ) : longint ;
begin
  Result := NPERR_NO_ERROR ;
end ;

procedure TPlugin.StreamAsFile( Stream : PNPStream ;
                                FName  : string ) ;
begin
end ;

procedure TPlugin.Print( PlatformPrint : PNPPrint ) ;
begin
end ;

procedure TPlugin.URLNotify( URL      : string ;
                             Reason   : TNPReason ;
                             var NotifyData ) ;
begin
end ;

function  TPlugin.GetJavaClass : JRef ;
begin
  Result := NIL ;
end ;

function TPlugin.GetScriptableObject: PNPObject;
begin
  if (m_pScriptableObject = nil) then
    m_pScriptableObject := NPN_CreateObject(FInstance, @cNPClass);
  if (m_pScriptableObject <> nil) then
    // Retain even newly created object. It will be released in the destructor.
    NPN_RetainObject(m_pScriptableObject);
  Result:=m_pScriptableObject;
end;

function TPlugin.GetProperty(name: TNPIdentifier;
  myresult: PNPVariant): Boolean;
var
  name_: PChar;
  value: Variant;
begin
  Result:=HasProperty(name);
  if Result then begin
    name_ := NPN_UTF8FromIdentifier(name);
    value := GetPropValue(Self, name_, true);
    Result := VariantToNPVariant(value, myresult);
  end;  
end;

function TPlugin.HasMethod(name: TNPIdentifier): Boolean;
var
  name_: PChar;
begin
  name_ := NPN_UTF8FromIdentifier(name);
  Result := MethodAddress(name_) <> nil;
end;

function TPlugin.HasProperty(name: TNPIdentifier): Boolean;
var
  name_: PChar;
begin
  name_ := NPN_UTF8FromIdentifier(name);
  Result := IsPublishedProp(Self, name_);
end;

procedure TPlugin.Invalidate;
begin
end;

function TPlugin.ConvertToArray(const args: PNPVariant; argCount: Cardinal):  TArrayOleVariant;
var
  I: Integer;
  ptr: PNPVariant;
begin
  SetLength(Result, argCount);
  if args = nil then
    exit;
  ptr := args;
  for I := 0 to argCount - 1 do begin
    Result[I] := NPVariantToVariant(ptr);
    Inc(ptr);
  end;
end;

function TPlugin.Invoke(name: TNPIdentifier; const args: PNPVariant;
  argCount: Cardinal; result_: PNPVariant): Boolean;
var
  name_: PChar;
  method: TNPApiPublicMethod;
  ret: OleVariant;
begin
  name_ := NPN_UTF8FromIdentifier(name);
  {$ifopt D+} NPP_DebugOut(Format('Calling method %s, params count: %d', [name_, argCount])); {$endif}
  method := MethodAddress(name_);
  if @method = nil then
  begin
    Result := False;
    Exit;
  end;
  ret := method(Self, ConvertToArray(args, argCount));
  Result := VariantToNPVariant(ret, result_);
end;

function TPlugin.InvokeDefault(const args: PNPVariant;
  argCount: Cardinal; result_: PNPVariant): Boolean;
begin
  Result := False;
end;

function TPlugin.RemoveProperty(name: TNPIdentifier): Boolean;
begin
  Result := False;
end;

function TPlugin.SetProperty(name: TNPIdentifier;
  value: PNPVariant): Boolean;
var
  name_: PChar;
begin
  name_ := NPN_UTF8FromIdentifier(name);
  SetPropValue(Self, name_, NPVariantToVariant(value) );
  Result := True;
end;

procedure TPlugin.SetException(const msg: string);
var
  s: string;
begin
  try
    {$ifopt D+} NPP_DebugOut('Exception: ' + msg); {$endif}
    s:=UTF8Encode(msg);
    NPN_SetException(m_pScriptableObject, PAnsiChar(s));
  except
    { prevent any exception from leaking out of DLL }
  end;
end;

function TPlugin.GetBrowserWindowObject: IBrowserObject;
var
  obj: PNPObject;
  res: TNPError;
begin
  res:=NPN_GetValue(FInstance, NPNVWindowNPObject, @obj);
  if res <> NPERR_NO_ERROR then
    raise Exception.CreateFmt('Error getting a browser window object: %d', [res]);
  Result:=TBrowserObject.Create(Self, obj);
end;

function TPlugin.NPVariantToVariant(value: PNPVariant): Variant;
begin
  Result:=NPPlugin.NPVariantToVariant(value, Self);
end;

function TPlugin.GetBrowserWindowHandle: HWND;
var
  res: TNPError;
begin
  res:=NPN_GetValue(FInstance, NPNVnetscapeWindow, @Result);
  if res <> NPERR_NO_ERROR then
    Result:=0;
end;

function TPlugin.GetBrowserType: TBrowserType;
var
  s: string;
begin
  if FBrowserType = btInvalid then begin
    s:=NPN_UserAgent(FInstance);
    if Pos('Opera', s) <> 0 then
      FBrowserType:=btOpera
    else
    if Pos('Chrome', s) <> 0 then
      FBrowserType:=btChrome
    else
    if Pos('Gecko', s) <> 0 then
      FBrowserType:=btMozilla
    else
      FBrowserType:=btUnknown;  
  end;
  Result:=FBrowserType;
end;

{ TBrowserObject }

constructor TBrowserObject.Create(PlugIn: TPlugin; obj: PNPObject);
begin
  FPlugIn:=PlugIn;
  FObject:=obj;
  inherited Create;
end;

function TBrowserObject.Evaluate(const Script: string): OleVariant;
var
  s, res: TNPVariant;
begin
  STRING_TO_NPVARIANT(Script, @s);
  try
    if not NavigatorFuncs.Evaluate(FPlugIn.Instance, FObject, @s.value.stringValue, @res) then
      raise Exception.Create('Evaluate failed.');
    Result:=FPlugIn.NPVariantToVariant(@res);
    NPN_ReleaseVariantValue(@res);
  finally
    NPN_ReleaseVariantValue(@s);
  end;
end;

function TBrowserObject.GetObject(const PropertyName: string): IBrowserObject;
begin
  Result:=VarAsObject(GetProperty(PropertyName), True);
end;

function TBrowserObject.GetProperty(const PropertyName: string): OleVariant;
var
  res: TNPVariant;
begin
  if not NavigatorFuncs.GetProperty(FPlugIn.FInstance, FObject, NPN_GetStringIdentifier(PChar(PropertyName)), @res) then
    raise Exception.CreateFmt('Failed to get property ''%s''.', [PropertyName]);
  Result:=FPlugIn.NPVariantToVariant(@res);
  NPN_ReleaseVariantValue(@res);
end;

function TBrowserObject.HasMethod(const MethodName: string): boolean;
begin
  Result:=NavigatorFuncs.HasMethod(FPlugIn.FInstance, FObject, NPN_GetStringIdentifier(PChar(MethodName)));
end;

function TBrowserObject.HasProperty(const PropertyName: string): boolean;
begin
  Result:=NavigatorFuncs.HasProperty(FPlugIn.FInstance, FObject, NPN_GetStringIdentifier(PChar(PropertyName)));
end;

function TBrowserObject.Invoke(const MethodName: string; const Params: array of OleVariant): OleVariant;
var
  p, pp: PNPVariant;
  res: TNPVariant;
  i: integer;
begin
  GetMem(p, SizeOf(TNPVariant)*Length(Params));
  FillChar(p^, SizeOf(TNPVariant)*Length(Params), 0);
  try
    pp:=p;
    for i:=0 to High(Params) do begin
      VariantToNPVariant(Params[i], pp);
      Inc(pp);
    end;
    if not NavigatorFuncs.Invoke(FPlugIn.FInstance, FObject, NPN_GetStringIdentifier(PChar(MethodName)), p, Length(Params), @res) then
      raise Exception.CreateFmt('Call to method ''%s'' failed.', [MethodName]);
    Result:=FPlugIn.NPVariantToVariant(@res);
    NPN_ReleaseVariantValue(@res);
  finally
    pp:=p;
    for i:=0 to High(Params) do begin
      NPN_ReleaseVariantValue(pp);
      Inc(pp);
    end;
    FreeMem(p);
  end;
end;

function TBrowserObject.InvokeDefault(const Params: array of OleVariant): OleVariant;
var
  p, pp: PNPVariant;
  res: TNPVariant;
  i: integer;
begin
  GetMem(p, SizeOf(TNPVariant)*Length(Params));
  FillChar(p^, SizeOf(TNPVariant)*Length(Params), 0);
  try
    pp:=p;
    for i:=0 to High(Params) do begin
      VariantToNPVariant(Params[i], pp);
      Inc(pp);
    end;
    if not NavigatorFuncs.InvokeDefault(FPlugIn.FInstance, FObject, p, Length(Params), @res) then
      raise Exception.Create('Call to default method failed.');
    Result:=FPlugIn.NPVariantToVariant(@res);
    NPN_ReleaseVariantValue(@res);
  finally
    pp:=p;
    for i:=0 to High(Params) do begin
      NPN_ReleaseVariantValue(pp);
      Inc(pp);
    end;
    FreeMem(p);
  end;
end;

function TBrowserObject.QueryInterface(const IID: TGUID; out Obj): HResult;
begin
  Result:=E_NOINTERFACE;
end;

procedure TBrowserObject.RemoveProperty(const PropertyName: string);
begin
  if not NavigatorFuncs.RemoveProperty(FPlugIn.FInstance, FObject, NPN_GetStringIdentifier(PChar(PropertyName))) then
    raise Exception.CreateFmt('Failed to remove property ''%s''.', [PropertyName]);
end;

procedure TBrowserObject.SetProperty(const PropertyName: string; const Value: OleVariant);
var
  v: TNPVariant;
begin
  VariantToNPVariant(Value, @v);
  try
    if not NavigatorFuncs.SetProperty(FPlugIn.FInstance, FObject, NPN_GetStringIdentifier(PChar(PropertyName)), @v) then
      raise Exception.CreateFmt('Failed to set property ''%s''.', [PropertyName]);
  finally
    NPN_ReleaseVariantValue(@v);
  end;
end;

function TBrowserObject._AddRef: Integer;
begin
  NPN_RetainObject(FObject);
  Result := InterlockedIncrement(FRefCount);
end;

function TBrowserObject._Release: Integer;
begin
  NPN_ReleaseObject(FObject);
  Result := InterlockedDecrement(FRefCount);
  if Result = 0 then
    Destroy;
end;

procedure DefDebugOut(const Msg: string);
begin
  OutputDebugStringA(PChar(Msg + #13#10));
end;

procedure Write2EventLog(Source, Msg: string; eventType: Integer = EVENTLOG_ERROR_TYPE);
var h: THandle;
    ss: array [0..0] of pchar;
begin
    ss[0] := pchar(Msg);
    h := RegisterEventSource(nil,  // uses local computer
             pchar(Source));          // source name
    if h <> 0 then
      ReportEvent(h,           // event log handle
            eventType,  // event type
            0,                    // category zero
            0,        // event identifier
            nil,                 // no user security identifier
            1,                    // one substitution string
            0,                    // no data
            @ss,     // pointer to string array
            nil);                // pointer to data
    DeregisterEventSource(h);
end;

initialization
  IsMultiThread:=True;
  NPP_DebugOut:=@DefDebugOut;
  Plugins := TPlugins.Create;

finalization
  Plugins.Free ;
end.

