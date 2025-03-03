import time
import gspread
import codecs
import os

tableHeader = "1SR2HV6WTnLmGvu7I2h3QhBHUfEAWucPRsGd8_tEwQLI"
tableWorkSheetHeader = "LocalizationExport"

tableDescriptions = "1xG_VWepZ1l3bxYz1vzMjrUznIbEvNr1bcswPr5S3ESs"
tableWorkSheetDesc1 = "LocalizationExport"
tableWorkSheetDesc2 = "LocalizationExport_2"
tableWorkSheetDesc3 = "LocalizationExport_3"

gc = gspread.oauth()

sheetHeader = gc.open_by_key(tableHeader)
workHeader = sheetHeader.worksheet(tableWorkSheetHeader)

strLanColumn = "O"
strReadColumn = "P"

startRead = 2
endRead = 15

for i in range(startRead, endRead):
    cellColumnVal = strReadColumn + str(i)
    cellVal = workHeader.acell(cellColumnVal).value

    cellVal = cellVal.replace("\x00", "")

    cellColumnLan = strLanColumn + str(i)
    cellLan = workHeader.acell(cellColumnLan).value

    cellLan = str.replace(cellLan, " ", "")

    print("Export Header: " + cellLan)

    path = cellLan + "/";

    isExistFolder = os.path.exists(path)

    if not isExistFolder:
        os.makedirs(path)

    with codecs.open(cellLan + "/" + cellLan + "_Header" + ".xml", "w", "utf-8") as steram:
        steram.write(cellVal)


sheetDescription = gc.open_by_key(tableDescriptions)
workDesc1 = sheetDescription.worksheet(tableWorkSheetDesc1)
workDesc2 = sheetDescription.worksheet(tableWorkSheetDesc2)
workDesc3 = sheetDescription.worksheet(tableWorkSheetDesc3)

for i in range(startRead, endRead):
    for idx, workD in enumerate([workDesc1, workDesc2, workDesc3]):

        time.sleep(5)

        cellColumnVal = strReadColumn + str(i)
        cellVal = workD.acell(cellColumnVal).value

        cellVal = cellVal.replace("\x00", "")

        cellColumnLan = strLanColumn + str(i)
        cellLan = workD.acell(cellColumnLan).value

        cellLan = str.replace(cellLan, " ", "")

        print("Export Description: " + cellLan + "_" + str(idx))

        path = cellLan + "/";

        isExistFolder = os.path.exists(path)

        if not isExistFolder:
            os.makedirs(path)

        with codecs.open(cellLan + "/" + cellLan + "_Description_" + str(idx + 1) + ".xml", "w", "utf-8") as steram:
            steram.write(cellVal)