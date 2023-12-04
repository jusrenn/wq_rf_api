*** Settings ***
Documentation       Bu suite'te HerokuApp'in API servislerinin testi yapilir.

Library             RequestsLibrary
Library             OperatingSystem
Library             String
Library             Collections


*** Variables ***
${BASE_URL}=    https://restful-booker.herokuapp.com
&{HEADERS}=     Content-Type=application/json


*** Test Cases ***
Get Booking Ids
    [Documentation]    Bu test tum rezervasyon kayitlarinin idlerini getirir.
    [Tags]    getbookingids
    ${END_POINT}=    Set Variable    /booking

    Create Session    getbookingids    ${BASE_URL}    verify=True
    ${res}=    GET On Session    getbookingids    ${END_POINT}

    Status Should Be    200

    # ${contenttype}=    Set Variable    ${res.headers}[Content-Type]
    # Should Be Equal    application/json; charset\=utf-8    ${contenttype}

Create Booking
    [Documentation]    Yeni bir rezervasyon olusturur.
    [Tags]    createbooking
    ${END_POINT}=    Set Variable    /booking

    ${bookingdates}=    Create Dictionary
    ...    checkin=2023-01-01
    ...    checkout=2023-01-01

    ${BODY}=    Create Dictionary
    ...    firstname=Yusuf
    ...    lastname=Renk
    ...    totalprice=1000
    ...    depositpaid=false
    ...    bookingdates=${bookingdates}
    ...    additionalneeds=Breakfast

    Create Session    createbooking    ${BASE_URL}    headers=${HEADERS}    verify=True
    ${res}=    POST On Session    createbooking    ${END_POINT}    json=${BODY}

    Status Should Be    200

    ${ID}=    Set Variable    ${res.json()}[bookingid]
    Set Suite Variable    ${ID}

Get Booking
    [Documentation]    Bu sorgu gonderidigim id'ye ait rezervasyon kaydini verir.
    ${END_POINT}=    Set Variable    /booking/${ID}

    Create Session    getbooking    ${BASE_URL}    verify=True
    ${res}=    GET On Session    getbooking    ${END_POINT}

    Status Should Be    200

    ${firstname}=    Set Variable    ${res.json()}[firstname]
    ${lastname}=    Set Variable    ${res.json()}[lastname]
    ${totalprice}=    Set Variable    ${res.json()}[totalprice]
    ${checkout}=    Set Variable    ${res.json()}[bookingdates][checkout]

    Should Be Equal    ${firstname}    Yusuf
    Should Be Equal    ${lastname}    Renk
    # ${expected_price}=    Convert To Integer    1000
    # Should Be Equal    ${totalprice}    ${expected_price}
    Should Be Equal As Integers    ${totalprice}    1000
    Should Be Equal    ${checkout}    2023-01-01

Update Booking
    [Documentation]    Verilen ID'ye ait rezervasyon kaydini gunceller
    [Setup]    Create Token

    ${END_POINT}=    Set Variable    /booking/${ID}

    Set To Dictionary    ${HEADERS}
    ...    Accept=application/json
    ...    Cookie=token=${TOKEN}

    ${bookingdates}=    Create Dictionary
    ...    checkin=2023-11-09
    ...    checkout=2023-11-07

    ${BODY}=    Create Dictionary
    ...    firstname=Veli
    ...    lastname=Yilmaz
    ...    totalprice=2000
    ...    depositpaid=true
    ...    bookingdates=${bookingdates}
    ...    additionalneeds=Breakfast

    Create Session    updatebooking    ${BASE_URL}    headers=${HEADERS}    verify=True
    ${res}=    PUT On Session    updatebooking    ${END_POINT}    json=${BODY}

    Status Should Be    200
    Should Be Equal    ${res.json()}[firstname]    Veli
    Should Be Equal    ${res.json()}[lastname]    Yilmaz
    Should Be Equal As Integers    ${res.json()}[totalprice]    2000
    Should Be Equal    ${res.json()}[bookingdates][checkin]    2023-11-09
    Should Be Equal    ${res.json()}[bookingdates][checkout]    2023-11-07
    ${durum}=    Convert To Boolean    True
    Should Be Equal    ${res.json()}[depositpaid]    ${durum}

Delete Booking
    [Documentation]    Bu test verilen ID'ye ait rezervasyonu siler.

    ${END_POINT}=    Set Variable    /booking/${ID}
    ${Yeni_Token}=    Create And Return Token

    Set To Dictionary    ${HEADERS}    Cookie=token=${Yeni_Token}

    Create Session    deletebooking    ${BASE_URL}    headers=${HEADERS}    verify=True
    ${res}=    DELETE On Session    deletebooking    ${END_POINT}

    Status Should Be    201


*** Keywords ***
Create Token
    [Documentation]    Yeni token olusturur ve set suite variable ile tum suite icerisinden
    ...    ${TOKEN} degiskenine erismeme olanak tanir.
    ${END_POINT}=    Set Variable    /auth

    ${BODY}=    Create Dictionary
    ...    username=admin
    ...    password=password123

    # ${BODY2}=    Set Variable    { "username" : "admin", "password" : "password123"}

    Create Session    createToken    ${BASE_URL}    headers=${HEADERS}    verify=True

    # Eger variable olarak body yollayacaksam asagidaki gibi data= paramteresi ile bodyi tanimliyorum.
    # ${response}=    POST On Session    createToken    ${END_POINT}    data=${BODY2}

    # Eger dictionary olarak body yollayacaksam asagidaki gibi json= parametresi ile bodyi tanimliyorum.
    ${response}=    POST On Session    createToken    ${END_POINT}    json=${BODY}

    Status Should Be    200
    Request Should Be Successful

    ${TOKEN}=    Set Variable    ${response.json()}[token]
    Set Suite Variable    ${TOKEN}

Create And Return Token
    [Documentation]    Yeni bir token olusturur ve olusturulan bu tokeni döndurur.
    ${END_POINT}=    Set Variable    /auth

    ${BODY}=    Create Dictionary
    ...    username=admin
    ...    password=password123

    Create Session    createToken    ${BASE_URL}    headers=${HEADERS}    verify=True
    ${response}=    POST On Session    createToken    ${END_POINT}    json=${BODY}

    Status Should Be    200
    ${tokenn}=    Set Variable    ${response.json()}[token]
    RETURN    ${tokenn}
