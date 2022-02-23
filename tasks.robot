*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium    auto_close=${FALSE}    timeout=20
Library           RPA.PDF
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.Archive
Library           OperatingSystem
Library           RPA.Dialogs
Library           RPA.Robocorp.Vault

*** Tasks ***
Orders robots from RobotSpareBin Industries Inc
    Open a website
    Download a CSV file
    ${orders}=    Read table from CSV    orders.csv    header=True
    FOR    ${order}    IN    @{orders}
        Give consent
        Wait Until Keyword Succeeds    10x    5s    Fill the order on website    ${order}
        # Fill the order on website    ${order}
        # Wait Until Keyword Succeeds    3x    5s    Go to receipt
        Saves the orders HTML receipt as a PDF file    ${order}[Order number]
        Add Screenshot to PDF receipt    ${order}[Order number]
        Finalize order
    END
    Creates ZIP archive of the receipts and the images
    [Teardown]    Tidy up

*** Keywords ***
Open a website
    ${urls}=    Get Secret    URLs
    Open Available Browser    ${urls}[order-robot]

Get file URL
    Add heading    Please enter URL of the file to download:
    Add text input    url    placeholder= https://robotsparebinindustries.com/orders.csv
    ${result}=    Run dialog
    [Return]    ${result.url}

Download a CSV file
    ${file_download_URL}=    Get file URL
    Download    ${file_download_URL}    overwrite=True

Give consent
    Wait Until Element Is Visible    css:div.alert-buttons
    Click Button    OK

Fill the order on website
    [Arguments]    ${order}
    Select From List By Value    head    ${order}[Head]
    Select Radio Button    body    ${order}[Body]
    Input Text    xpath:/html/body/div/div/div[1]/div/div[1]/form/div[3]/input    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Take a screenshot of the robot
    Go to receipt

Take a screenshot of the robot
    Click Button    preview
    Wait Until Element Is Visible    css:#robot-preview-image > img:nth-child(1)
    Wait Until Element Is Visible    css:#robot-preview-image > img:nth-child(2)
    Wait Until Element Is Visible    css:#robot-preview-image > img:nth-child(3)
    Screenshot    css:div#robot-preview-image    ${OUTPUT_DIR}${/}robot_preview_image.png

Go to receipt
    Click Button    order
    Wait Until Element Is Visible    id:receipt

Saves the orders HTML receipt as a PDF file
    [Arguments]    ${order_number}
    ${sales_results_html}=    Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${sales_results_html}    ${OUTPUT_DIR}${/}receipts${/}receipt_${order_number}.pdf

Add Screenshot to PDF receipt
    [Arguments]    ${order_number}
    ${files}=    Create List    ${OUTPUT_DIR}${/}robot_preview_image.png
    Add Files To Pdf    ${files}    ${OUTPUT_DIR}${/}receipts${/}receipt_${order_number}.pdf    append=True

Finalize order
    Click Button    order-another

Creates ZIP archive of the receipts and the images
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}receipts_arch.zip

Tidy up
    Remove File    ${OUTPUT_DIR}${/}robot_preview_image.png
    Close Browser
