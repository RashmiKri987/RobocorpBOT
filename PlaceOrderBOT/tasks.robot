*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library           RPA.Browser.Selenium
Library           RPA.HTTP
Library           RPA.Tables
Library           RPA.PDF
Library           RPA.Desktop
Library           RPA.Archive
Library           RPA.Dialogs
Library           RPA.Robocloud.Secrets

*** Keywords ***
Get CSV URL from user
    #Allow user to input order URL
    Create Form    Orders File URL
    Add Text Input    URL of orders    orders_url
    &{response}=    Request Response
    [Return]    ${response["orders_url"]}

*** Keywords ***
Open the robot order website
    #Get robot order URL from vault
    ${secret}=    Get Secret    robotorder_info
    Open Available Browser      ${secret}[order_url]
    Wait Until Page Contains Element    xpath://button[normalize-space()='OK']

*** Keywords ***
Close the annoying modal
    Click Element If Visible    xpath://button[normalize-space()='OK']

*** Keywords ***
Get orders
    [Arguments]     ${csv_url}
    Download    ${csv_url}    overwrite=True
    ${table}=    Read Table From Csv    orders.csv   
    [RETURN]     ${table}

*** Keywords ***
Fill the form
    [Arguments]     ${order}
    #Choose head
    Select From List By Value     xpath://select[@id='head']       ${order}[Head]
    # Choose body
    Click Element When Visible    xpath://input[@id='id-body-${order}[Body]'] 
    # Type number for legs
    RPA.Desktop.Press Keys    tab
    Type Text    ${order}[Legs]
    # Enter address
    Input Text                    xpath://input[@id='address']    ${order}[Address]

*** Keywords ***
Preview the robot
    Click Button When Visible     xpath://button[normalize-space()='Preview']

*** Keywords ***
Submit the order
    Click Button When Visible         xpath://button[normalize-space()='Order']
    #Order is submitted successfilly if receipt is visible    
    Wait Until Element Is Visible     xpath://div[@id='receipt']

*** Keywords ***
Store the receipt as a PDF file
    [Arguments]    ${order_number}
    Wait Until Element Is Visible    xpath://div[@id='receipt']
    ${receipt_html}=    Get Element Attribute    xpath://div[@id='receipt']    outerHTML
    Html To Pdf    ${receipt_html}    ${CURDIR}${/}receipts${/}Order-${order_number}.pdf
    [Return]    ${CURDIR}${/}receipts${/}Order-${order_number}.pdf
    
*** Keywords ***
Take a screenshot of the robot
    [Arguments]    ${order_number}
    #To the screenshot complete robot
    Click Element When Visible    xpath://img[@alt='Head']
    Click Element When Visible    xpath://img[@alt='Body']
    Click Element When Visible    xpath://img[@alt='Legs']
   
    Capture Element Screenshot    xpath://div[@id='robot-preview-image']  ${OUTPUT_DIR}${/}Image${/}Image-${order_number}.png
    [Return]    ${OUTPUT_DIR}${/}Image${/}Image-${order_number}.png

*** Keywords ***
Embed the robot screenshot to the receipt PDF file
    [Arguments]        ${robot_screenshot}    ${pdf_file}
    Open Pdf       ${pdf_file}
    Add Watermark Image To Pdf    ${robot_screenshot}    ${pdf_file}
    Close Pdf    ${pdf_file}

*** Keywords ***
Go to order another robot
    Click Button When Visible     xpath://button[normalize-space()='Order another robot']

*** Keywords ***
Create a ZIP file of the receipts
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipts    ${OUTPUT_DIR}${/}Orders.zip

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    ${csv_url}=    Get CSV URL from user
    Open the robot order website
    Close the annoying modal
    ${orders}=    Get orders    ${csv_url}
    FOR    ${order}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${order}
        Preview the robot
        Wait Until Keyword Succeeds    10x    1 sec    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${order}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${order}[Order number] 
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    Create a ZIP file of the receipts

