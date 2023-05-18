*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    auto_close=${False}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.PDF
Library             RPA.Desktop
Library             Process
Library             RPA.Archive
Library             RPA.FileSystem


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    Get Orders
    Archive Output PDFs
    # Cleanup Directory
    [Teardown]    Close The Browser


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order
    Download csv file

Download csv file
    [Documentation]    This keyword downloads the csv file containing orders from a http url.
    Download
    ...    https://robotsparebinindustries.com/orders.csv
    ...    %{ROBOT_ROOT}${/}orders.csv
    ...    overwrite=${True}

Close the annoying modal
    Click Element If Visible    xpath://*[@id="root"]/div/div[2]/div/div/div/div/div/button[1]

Fill And Submit One Order
    [Arguments]    ${order}
    Close the annoying modal
    Select From List By Index    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text When Element Is Visible    css:.form-control    ${order}[Legs]
    Input Text When Element Is Visible    address    ${order}[Address]
    Click Button    xpath://*[@id="preview"]
    ${preview}=    Take Screenshot of Robot    ${order}

    Wait Until Keyword Succeeds    10x    0.5s    Click Button and Verify URL
    ${pdf_file}=    Save Receipt as PDF    ${order}
    Add Preview to PDF    ${preview}    ${pdf_file}    ${order}

Order Another Robot
    Click Button    xpath://*[@id="order-another"]

Get Orders
    @{orders}=    Read table from CSV    %{ROBOT_ROOT}${/}orders.csv
    FOR    ${order}    IN    @{orders}
        Fill And Submit One Order    ${order}
        Order Another Robot
    END

Save Receipt as PDF
    [Arguments]    ${order}
    ${receipt_html}=    Get Element Attribute    xpath://*[@id="receipt"]    outerHTML
    ${order_number}=    Get Variable Value    ${order}[Order number]
    ${pdf_file}=    Catenate    SEPARATOR=${/}    ${OUTPUT_DIR}    receipts    ${order_number}.pdf
    Log    ${pdf_file}
    Html To Pdf    ${receipt_html}    ${pdf_file}
    RETURN    ${pdf_file}

Click Button and Verify URL
    Click Element    xpath://*[@id="order"]
    Wait Until Page Contains Element    xpath://*[@id="order-another"]

Take Screenshot of Robot
    [Arguments]    ${order}
    Wait Until Page Contains Element    xpath://*[@id="robot-preview-image"]
    Wait Until Element Is Visible    xpath://*[@id="robot-preview-image"]
    Sleep    1s
    ${preview_file}=    Catenate    SEPARATOR=${/}    ${OUTPUT_DIR}    screenshot    ${order}[Order number].png
    Capture Element Screenshot    xpath://*[@id="robot-preview-image"]    ${preview_file}
    RETURN    ${preview_file}

Add Preview to PDF
    [Arguments]    ${preview}    ${pdf_file}    ${order}
    Open Pdf    ${pdf_file}
    ${files}=    Create List
    ...    ${pdf_file}
    ...    ${preview}
    Add Files To Pdf    ${files}    ${OUTPUT_DIR}${/}screenshot${/}${order}[Order number].pdf
    Close Pdf

Archive Output PDFs
    Archive Folder With Zip    ${OUTPUT_DIR}${/}screenshot    ${OUTPUT_DIR}${/}PDF.zip    include=*.pdf

Cleanup Directory
    Remove Directory    ${OUTPUT_DIR}${/}screenshot    True
    Remove Directory    ${OUTPUT_DIR}${/}receipts    True

Close The Browser
    Close Browser
