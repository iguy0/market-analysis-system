#ifndef MAS_INCLUDE
#define MAS_INCLUDE
//+---------------------------------------------------------------------------+
//|                                                           MAS_Include.mqh |
//|                                          Copyright 2016, Terentew Aleksey |
//|                                 https://www.mql5.com/ru/users/terentjew23 |
//+---------------------------------------------------------------------------+
#property copyright     "Copyright 2016, Terentew Aleksey"
#property link          "https://www.mql5.com/ru/users/terentjew23"
#property strict
#include                <MAS_MasterWindows.mqh>
//+---------------------------------------------------------------------------+
struct ForecastHeader {
    int         Version;
    string      Copyright;
    string      SymbolF;
    int         PeriodF;
    int         DigitsF;
    datetime    StartTS;
    datetime    EndTS;
    int         Depth;
};
string      mainSavePath = "MAS_MarketData/";
string      mainReadPath = "MAS_Prediction/";
double      fHigh_Buffer[];
double      fLow_Buffer[];
double      fClose_Buffer[];
ulong       tickCount;

//+---------------------------------------------------------------------------+
//| Functions                                                                 |
//+---------------------------------------------------------------------------+
bool NewBar(const int tf, const string symb = "")
{
    static datetime lastTime = 0;
    bool condition = false;
    if( lastTime != TimeCurrent() ) {
        condition = ( ( TimeCurrent() - lastTime >= PeriodSeconds(tf) ) || 
                      ( TimeCurrent() % PeriodSeconds(tf) == 0 ) );
        if( condition ) {
            lastTime  = TimeCurrent();
        }
    } 
    return condition;
};

bool NewForecast(const string symb)
{
    return false;
};

bool ReadConfig(const string file, string &list[][64], bool &symbolsWrited)
{
    string fileBuffer[100][256], symbolsString;
    int size, idx = 0;
    ushort sep = StringGetChar( ";", 0 );
    if( !symbolsWrited )
        GetSymbolsString( true, symbolsString );
    int config = FileOpen( file, FILE_READ | FILE_SHARE_READ | FILE_TXT );
    if( config != INVALID_HANDLE ) {
        while( !FileIsEnding( config ) ) {
            fileBuffer[idx][0] = FileReadString( config );
            idx++;
            //Print( "read - " + fileBuffer[idx-1][0]);
            if( idx >= ArraySize( fileBuffer ) )
                ArrayResize( fileBuffer, idx + 100 );
        }
        FileClose( config );
    } else {
        PrintFormat( "Config file not open. %d", GetLastError() );
        return false;
    }
    size = idx; idx = 0;
    while( idx < size ) {
        if( StringFind( fileBuffer[idx][0], "[Main]" ) >= 0 ) {
            idx++;
            if( StringFind( fileBuffer[idx][0], "Kit_Names=" ) >= 0 ) {
			    string tmp = StringSubstr( fileBuffer[idx][0], 10 );
			    StringReplace( tmp, "\"", "" );
                StringSplitMAS( tmp, ';', list );
            }
            if( StringFind( fileBuffer[idx+1][0], "Symbols=" ) < 0 ) {
                StringAdd( fileBuffer[idx][0], "\r\nSymbols=" + symbolsString + 
                                               "\r\nMt4_Account=" + IntegerToString(AccountNumber()) );
                symbolsWrited = true;
                break;
            } else Print( "check else symbWrited" ); // debug
        }
        idx++;
    }
    config = FileOpen( file, FILE_WRITE | FILE_TXT );
    if( config != INVALID_HANDLE ) {
        for( idx = 0; idx < size; idx++ )
            FileWriteString( config, fileBuffer[idx][0] + "\r\n" );
        FileClose( config );
    } else {
        PrintFormat( "Config file not opened for write. %d", GetLastError() );
        return false;
    }
    if( ArraySize(list) <= 0 )
        return false;
    return true;
};

void ReadKitConfig(const string file, const string kit,
                    string &inputList[][64], string &outputList[][64], int &depth)
{
    string tmpString, section = StringConcatenate( "[", kit, "]" );
    int config = FileOpen( file, FILE_READ | FILE_SHARE_READ | FILE_TXT );
    if( config != INVALID_HANDLE ) {
        while( !FileIsEnding( config ) ) {
            tmpString = FileReadString( config );
            if( StringFind( tmpString, section ) >= 0 ) {
                tmpString = FileReadString( config );
                if( StringFind( tmpString, "Depth_Prediction=" ) >= 0 ) {
                    depth = (int)StringToInteger( StringTrimRight( StringSubstr( tmpString, 17 ) ) );
                    tmpString = FileReadString( config );
                }
                if( StringFind( tmpString, "Input=" ) >= 0 ) {
                    StringReplace( tmpString, "\"", "" );
                    StringSplitMAS( StringTrimRight( StringSubstr( tmpString, 6 ) ), ';', inputList );
                    tmpString = FileReadString( config );
                }
                if( StringFind( tmpString, "Output=" ) >= 0 ) {
                    StringReplace( tmpString, "\"", "" );
                    StringSplitMAS( StringTrimRight( StringSubstr( tmpString, 7 ) ), ';', outputList );
                    tmpString = FileReadString( config );
                }
                PrintFormat( "Kit %s readed. Depth=%d, In=%s, Out=%s", section,
                                depth, inputList[0][0], outputList[0][0] );
            }
        }
        FileClose( config );
    } else {
        PrintFormat( "Config file not open. %d", GetLastError() );
    }
};

void SaveHistory(const string symb, const string copy, const char csvSep = ';')
{
    if( SymbolIsTime( symb ) )
        return;
    string  symbol, saveFile;
    int     timeframe = 0, limit, csvFile;
    SeparateMasSymbol( symb, symbol, timeframe );
    saveFile = StringConcatenate( mainSavePath, symb, ".csv" );
    limit = GetIndexFirstBar( timeframe );
    csvFile = FileOpen( saveFile, FILE_WRITE | FILE_CSV, csvSep );
    FileWrite( csvFile, 401, copy, symbol, timeframe, (int)MarketInfo( symbol, MODE_DIGITS ), 
                iTime( symbol, timeframe, limit - 1 ), iTime( symbol, timeframe, 0 ) );
    for( int i = limit - 1; i >= 0; i-- ) {
        FileSeek( csvFile, 0, SEEK_END );
        FileWrite( csvFile, iTime( symbol, timeframe, i ), 
                            DoubleToStr( iOpen(  symbol, timeframe, i ), (int)MarketInfo( symbol, MODE_DIGITS ) ), 
                            DoubleToStr( iHigh(  symbol, timeframe, i ), (int)MarketInfo( symbol, MODE_DIGITS ) ), 
                            DoubleToStr( iLow(   symbol, timeframe, i ), (int)MarketInfo( symbol, MODE_DIGITS ) ), 
                            DoubleToStr( iClose( symbol, timeframe, i ), (int)MarketInfo( symbol, MODE_DIGITS ) ), 
                            iVolume(_Symbol, timeframe, i) );
    }
    FileClose( csvFile );
    PrintFormat( "History file %s.csv saved. %s, %d", symb, symbol, timeframe );
};

void ReadForecastBarSeries(const string symb, datetime &seriesControlBars[], const char csvSep = ';')
{
    int idx = 0;
    ForecastHeader header;
    string readFile = StringConcatenate( mainReadPath, symb, ".csv" );
    int forecastFile = FileOpen( readFile, FILE_READ | FILE_SHARE_READ | FILE_CSV, csvSep );
    if( forecastFile != INVALID_HANDLE ) {
        if( ReadHeader( forecastFile, header ) ) {
            while( !FileIsEnding( forecastFile ) ) {
                if( idx >= ArraySize( seriesControlBars ) )
                    ArrayResize( seriesControlBars, ArraySize( seriesControlBars ) + 1 );
                seriesControlBars[idx] = ReadForcastBar( forecastFile, header.Depth );
                idx++;
            }
        } else 
            Print( "Wrong header of file! Reading is stopped." );
        FileClose( forecastFile );
    } else
        Print( "File not open! ", readFile, "; ", GetLastError() );
};

void ReadForecast(const string symb, const datetime controlBar, const char csvSep = ';')
{
    ForecastHeader header;
    string readFile = StringConcatenate( mainReadPath, symb, ".csv" );
    int forecastFile = FileOpen( readFile, FILE_READ | FILE_SHARE_READ | FILE_CSV, csvSep );
    if( forecastFile != INVALID_HANDLE ) {
        if( ReadHeader( forecastFile, header ) ) {
            while( !FileIsEnding( forecastFile ) ) {
                if( ReadForcastTS( forecastFile, header.PeriodF, header.Depth, controlBar ) )
                    break;
            }
        } else 
            Print( "Wrong header of file! Reading is stopped." );
        FileClose( forecastFile );
    } else
        Print( "File not open! ", readFile, "; ", GetLastError() );
}

bool ReadHeader(const int handle, ForecastHeader &fcst)
{
    bool ready = true;
    fcst.Version =   (int)StringToInteger( FileReadString( handle ) );
    fcst.Copyright = FileReadString( handle );
    fcst.SymbolF =   FileReadString( handle );
    fcst.PeriodF =   (int)StringToInteger( FileReadString( handle ) );
    fcst.DigitsF =   (int)StringToInteger( FileReadString( handle ) );
    fcst.StartTS =   StringToTime( FileReadString( handle ) );
    fcst.EndTS =     StringToTime( FileReadString( handle ) );
    fcst.Depth =     (int)StringToInteger( FileReadString( handle ) );
    PrintFormat( "Start TS - %s, End TS - %s.", TimeToString(fcst.StartTS), TimeToString(fcst.EndTS) );
    PrintFormat( "Readed forcast file %s%s.csv (v%d, depth=%d).", fcst.SymbolF, IntegerToString(fcst.PeriodF),
                    fcst.Version, fcst.Depth );
    if( fcst.SymbolF != _Symbol ) ready = false;
    
    return ready;
};

datetime ReadForcastBar(const int handle, const int depth)
{
    datetime bar = 0, tmp;
    for( int thr = 1; thr <= 3; thr++ ) {
        bar = StringToTime( FileReadString( handle ) );
        for( int i = 0; i < depth; i++ )
            FileReadString( handle );
        tmp = StringToTime( FileReadString( handle ) );
        if( tmp != bar )
            return bar;
    }
    return bar;
}

bool ReadForcastTS(const int handle, const int tf, const int depth, const datetime bar)
{
    datetime tmpBar;
    double buffer[11];
    ArrayInitialize( buffer, 0.0 );
    tmpBar = StringToTime( FileReadString( handle ) );
    if( tmpBar != bar ) {
        int trLine = depth * 3 + 2;
        for( int i = 0; i < trLine; i++ )
            FileReadString( handle );
        return false;
    } else {
        Print( "ReadForcastTS - bar found" );
        ArraysClear();
//      // Read the High array
        ArraySetAsSeries( fHigh_Buffer, true );
//      time = StringToTime( FileReadString( handle ) );
        for( int i = 0; i < depth; i++ )
            buffer[i] = StringToDouble( FileReadString( handle ) );
        fHigh_Buffer[GetIndexFromTime(bar, tf)] = buffer[0];
        ArraySetAsSeries( fHigh_Buffer, false );
//        for( int i = 0; i < depth; i++ )
//            fHigh_Buffer[GetIndexFromTime(bar, tf) + i] = StringToDouble( FileReadString( handle ) );
//      ArraySetAsSeries( fHigh_Buffer, false );//dbg
        FileReadString( handle ); //time
        for( int i = 0; i < depth; i++ )
            fLow_Buffer[GetIndexFromTime(bar, tf) + i] = StringToDouble( FileReadString( handle ) );
        FileReadString( handle ); //time
        for( int i = 0; i < depth; i++ )
            fClose_Buffer[GetIndexFromTime(bar, tf) + i] = StringToDouble( FileReadString( handle ) );
        return true;
    }
};/*
    datetime time;
    double buffer[11];
    // Read the High array
    ArraySetAsSeries( fHigh_Buffer, true );
    time = StringToTime( FileReadString(handle) );
    for( int i = 0; i < depthForecast; i++ )
        buffer[i] = StringToDouble( FileReadString(handle) );
    fHigh_Buffer[GetIndexFromTime(time)] = buffer[0];
    ArraySetAsSeries( fHigh_Buffer, false );
    // Read the Low array
    ArraySetAsSeries( fLow_Buffer, true );
    FileReadString(handle);     // time
    for( int i = 0; i < depthForecast; i++ )
        buffer[i] = StringToDouble( FileReadString(handle) );
    fLow_Buffer[GetIndexFromTime(time)] = buffer[0];
    ArraySetAsSeries( fLow_Buffer, false );
    // Read the Close array
    ArraySetAsSeries( fClose_Buffer, true );
    FileReadString(handle);     // time
    for( int i = 0; i < depthForecast; i++ )
        buffer[i] = StringToDouble( FileReadString(handle) );
    fClose_Buffer[GetIndexFromTime(time)] = buffer[0];
    ArraySetAsSeries( fClose_Buffer, false );
*/
void OpenNewWindow(const string symbol)
{
    
};

void CloseThisWindow()
{
    
};

int GetSymbolsList(const bool selected, string &symbols[])
{
    string symbolsFileName;
    int symbolsNumber, offset;
    if( selected ) 
        symbolsFileName = "symbols.sel";
    else
        symbolsFileName = "symbols.raw";
    int hFile = FileOpenHistory( symbolsFileName, FILE_BIN|FILE_READ );
    if( hFile < 0 ) 
        return -1;
    if( selected ) {
        symbolsNumber = ( (int)FileSize(hFile) - 4 ) / 128;
        offset = 116;
    } else { 
        symbolsNumber = (int)FileSize(hFile) / 1936;
        offset = 1924;
    }
    ArrayResize( symbols, symbolsNumber );
    if( selected )
        FileSeek( hFile, 4, SEEK_SET );
    for( int i = 0; i < symbolsNumber; i++ ) {
        symbols[i] = FileReadString( hFile, 12 );
        FileSeek( hFile, offset, SEEK_CUR );
    }
    FileClose( hFile );
    return symbolsNumber;
};

int GetSymbolsString(const bool selected, string &symbols)
{
    string symbolsList[];
    int size = GetSymbolsList( selected, symbolsList );
    if( size >= 1 ) {
        symbols = symbolsList[0];
        for( int i = 1; i < size; i++ )
            symbols = StringConcatenate( symbols, ";", symbolsList[i] );
    }
    return size;
};

int StringSplitMAS(const string string_value, const ushort separator, string &result[][64])
{
    if( StringLen( string_value ) <= 0 || string_value == NULL )
        return 0;
    int lastChar = 0, currentChar = 0, size = StringLen(string_value), sizeRes = 0, sepIdxs[50];
    ArrayInitialize( sepIdxs, 0 );
    for( int idx = 0; idx < size; idx++) {
        if( StringGetChar(string_value, idx) == separator ) {
            sepIdxs[sizeRes] = idx;
            sizeRes += 1;
            if( sizeRes >= ArraySize(sepIdxs) )
                ArrayResize( sepIdxs, ArraySize(sepIdxs) + 50 );
        }
    }
    ArrayResize( result, sizeRes + 1 );
    if( sizeRes == 0 ) {
        result[sizeRes][0] = string_value;
        return sizeRes + 1;
    }
    for( int idx = 0; idx <= sizeRes; idx++) {
        if( idx == 0 ) {
            result[idx][0] = StringSubstr( string_value, 0, sepIdxs[idx] );
            continue;
        }
        result[idx][0] = StringSubstr( string_value, sepIdxs[idx-1] + 1, 
                                                     sepIdxs[idx] - sepIdxs[idx-1] - 1 );
    }
    return sizeRes + 1;
};

void SeparateMasSymbol(const string masSymbol, string &symbol, int &period)
{
    int periods[] = {PERIOD_MN1, PERIOD_W1, PERIOD_D1, PERIOD_H4, PERIOD_H1,
                        PERIOD_M30, PERIOD_M15, PERIOD_M5, PERIOD_M1};
    int idx = 0;
    while( StringFind( masSymbol, IntegerToString(periods[idx]), 0 ) < 0 ) {
        idx++;
        if( idx > 8 ) {
            idx = -1;
            break;
        }
    }
    if( idx >= 0 ) {
        symbol = masSymbol;
        StringReplace( symbol, IntegerToString(periods[idx]), "" );
        period = periods[idx];
    } else {
        symbol = "";
        period = -1;
    }
};

void ArraysClear(const int size = 50)
{
    ArrayFree( fHigh_Buffer );
    ArrayFree( fLow_Buffer );
    ArrayFree( fClose_Buffer );
    ArrayResize( fHigh_Buffer, size );
    ArrayResize( fLow_Buffer, size );
    ArrayResize( fClose_Buffer, size );
};

int GetIndexFromTime(const datetime time, const int timeframe)
{
    int index = 0;
    while( iTime( _Symbol, timeframe, index ) >= time )
        index++;
    return index;
};

int GetIndexFirstBar(int timeframe)
{
    if( timeframe == PERIOD_D1 )
        return 60;
    else if( timeframe == PERIOD_H4 )
        return 60;
    else if( timeframe == PERIOD_H1 )
        return 60;
    else if( timeframe == PERIOD_M30 )
        return 180;
    else if( timeframe == PERIOD_M15 )
        return 360;
    else if( timeframe == PERIOD_M5 )
        return 360;
    else if( timeframe == PERIOD_M1 )
        return 360;
    else if( timeframe == PERIOD_MN1 )
        return 20;
    return 0;
};

bool SymbolIsTime(const string symb)
{
    if( (symb == "YEAR") || (symb == "MONTH") || (symb == "DAY") || 
        (symb == "YEARDAY") || (symb == "WEEKDAY") || 
        (symb == "HOUR") || (symb == "MINUTE") )
        return true;
    return false;
};

#ifdef MAS_MASTERWINDOWS
//+---------------------------------------------------------------------------+
//| UserInterface Class                                                       |
//+---------------------------------------------------------------------------+
int Mint[][3] =     { { 1, 0,   0  },
                      { 2, 100, 0  },
                      { 4, 100, 50 } };
string Mstr[][3] =  { { "MAS_Assistant", "",               "" },
                      { "Kit name",      "none",           "" },
                      { "Control Bar",   "hh:mm dd.MM.yy", "" } };
                      
class UiAssistant : public CWin
{
private:
    long            Y_hide;
    long            Y_obj;
    long            H_obj;
    long            idChart;
    int             idWind;
    string          nameMAKit;
    string          symbol;
    datetime        controlBars[];
    int             idx;
private:
    void Redraw(const int line, const string text) {
        bool del = true;
        string lineName = StringConcatenate( "MAS_Assistant.Exp.STR", line );
    /*  for( int i = 0; i < ObjectsTotal(idChart, idWind); i++ ) {
            string obj = ObjectName( i );
            Print( obj );
            if( StringFind( obj, lineName, 0 ) > 0 ) {
                del = ObjectDelete( idChart, obj );
            }
        }*/
        if( del ) {
            int Y = w_ypos + line * (Property.H + DELTA);
            if( line == 1 )
                STR1.Draw( lineName, w_xpos, Y, w_bsize, 100, "Kit name", text );
            else
                STR2.Draw( lineName, w_xpos, Y, w_bsize, 100, "Control Bar", text );
        } else {
            PrintFormat( "MAS_Error: Not found a graphic object - %d", GetLastError() );
        }
    }
public:
    void UiAssistant() { on_event = false; }
    void Run(const long chId, const int wId)
    {
        idChart = chId; idWind = wId;
        ObjectsDeleteAll( idChart, idWind, EMPTY );
        SetWin( "MAS_Assistant.Exp", 30, 40, 300, CORNER_RIGHT_UPPER );
        Draw( Mint, Mstr, 2 );
    }
    void SetMAKit(const string tmp) 
    { 
        nameMAKit = tmp;
        PrintFormat( "Selected kit - %s", nameMAKit );
    }
    void SetMASymbol(const string tmp) { symbol = tmp; }
    void SetControlBars(const datetime &bars[])
    {
        ArrayFree( controlBars ); ArrayResize( controlBars, 50 );
        for( int i = 0; i < ArraySize(bars); i++ )
            controlBars[i] = bars[i];
        Redraw( 2, TimeToString( controlBars[0] ) );
        idx = 0;
    }
    void Hide() { }
    void Deinit() { ObjectsDeleteAll( idChart, idWind, EMPTY ); }
    virtual void OnEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
    {
        if( on_event && StringFind(sparam, "MAS_Assistant.Exp", 0) >= 0 ) {
            STR0.OnEvent( id, lparam, dparam, sparam );
            STR1.OnEvent( id, lparam, dparam, sparam );
            STR2.OnEvent( id, lparam, dparam, sparam );
            if( (ENUM_CHART_EVENT)id == CHARTEVENT_OBJECT_CREATE ) {
                //--- создание графического объекта
                // добавить время текущего набора и контр.бара
            }
            if( (ENUM_CHART_EVENT)id == CHARTEVENT_OBJECT_ENDEDIT
                            && StringFind(sparam, ".STR1", 0) > 0 ) {
                Redraw( 1, nameMAKit );
            }
            if( (ENUM_CHART_EVENT)id == CHARTEVENT_OBJECT_CLICK
                            && StringFind(sparam, ".STR2", 0) > 0
                            && StringFind(sparam, ".Button3", 0) > 0 ) {
                if( idx > 0 ) {
                    idx = 0;
                    Redraw( 2, TimeToString( controlBars[idx] ) );
                    ReadForecast( symbol, controlBars[idx] );
                }
            }
            if( (ENUM_CHART_EVENT)id == CHARTEVENT_OBJECT_CLICK
                            && StringFind(sparam, ".STR2", 0) > 0
                            && StringFind(sparam, ".Button4", 0) > 0 ) {
                if( idx > 0 ) {
                    idx--;
                    Redraw( 2, TimeToString( controlBars[idx] ) );
                    ReadForecast( symbol, controlBars[idx] );
                }
            }
            if( (ENUM_CHART_EVENT)id == CHARTEVENT_OBJECT_CLICK
                            && StringFind(sparam, ".STR2", 0) > 0
                            && StringFind(sparam, ".Button5", 0) > 0 ) {
                if( idx < (ArraySize( controlBars ) - 1) ) {
                    idx++;
                    Redraw( 2, TimeToString( controlBars[idx] ) );
                    ReadForecast( symbol, controlBars[idx] );
                }
            }
            if( (ENUM_CHART_EVENT)id == CHARTEVENT_OBJECT_CLICK
                            && StringFind(sparam, ".STR2", 0) > 0
                            && StringFind(sparam, ".Button6", 0) > 0 ) {
                if( idx < (ArraySize( controlBars ) - 1) ) {
                    idx = ArraySize( controlBars ) - 1;
                    Redraw( 2, TimeToString( controlBars[idx] ) );
                    ReadForecast( symbol, controlBars[idx] );
                }
            }
            if( (ENUM_CHART_EVENT)id == CHARTEVENT_OBJECT_CLICK
                            && StringFind(sparam, ".Button0", 0) > 0 ) {
                Hide();
            }
            if( (ENUM_CHART_EVENT)id == CHARTEVENT_OBJECT_CLICK
                            && StringFind(sparam, ".Button1", 0) > 0 ) {
                Deinit();
                ExpertRemove();
            }
        }
    }
};
#endif // MAS_MASTERWINDOWS

#endif // MAS_INCLUDE
