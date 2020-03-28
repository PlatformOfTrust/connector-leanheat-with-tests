*** Settings ***
Library           Collections
Library           DateTime
Library           PoTLib
Library           REST         ${POT_API_URL}


*** Variables ***
${LOCAL_TZ}                  +02:00
${TESTENV}                   sandbox
${POT_API_URL}               https://api-${TESTENV}.oftrust.net
${APP_TOKEN}                 %{POT_ACCESS_TOKEN_APP1}
${CLIENT_SECRET}             %{CLIENT_SECRET_WORLD}
${PRODUCT_CODE}              %{PRODUCT_CODE}
&{FIRST_ID_SET}              site_name=lh_suokatu42_kuopio  series_id=3C2FEE_temp
&{SECOND_ID_SET}             site_name=lh_suokatu42_kuopio  series_id=3C2FEE_hum
@{IDS}                       &{FIRST_ID_SET}  &{SECOND_ID_SET}
${START_TIME}                2020-02-10 13:06:40
${END_TIME}                  2020-02-10 14:53:54
@{DATA_TYPES}                Temperature
&{BROKER_BODY_PARAMETERS}    ids=@{IDS}
...                          startTime=${START_TIME}
...                          endTime=${END_TIME}
...                          dataTypes=@{DATA_TYPES}
&{BROKER_BODY}               productCode=${PRODUCT_CODE}
...                          parameters=${BROKER_BODY_PARAMETERS}


*** Keywords ***
Fetch Data Product
    [Arguments]     ${body}
    ${signature}    Calculate PoT Signature          ${body}    ${CLIENT_SECRET}
    Set Headers     {"x-pot-signature": "${signature}", "x-app-token": "${APP_TOKEN}"}
    POST            /broker/v1/fetch-data-product    ${body}

Get Body
    [Arguments]          &{kwargs}
    ${body}              Copy Dictionary     ${BROKER_BODY}    deepcopy=True
    ${now}               Get Current Date    time_zone=UTC     result_format=%Y-%m-%dT%H:%M:%S.%fZ
    Set To Dictionary    ${body}             timestamp         ${now}
    Set To Dictionary    ${body}             &{kwargs}
    [Return]             ${body}

Fetch Data Product With Timestamp
    [Arguments]            ${increment}       ${time_zone}=UTC      ${result_format}=%Y-%m-%dT%H:%M:%S.%fZ
    ${timestamp}           Get Current Date
    ...                    time_zone=${time_zone}
    ...                    result_format=${result_format}
    ...                    increment=${increment}
    ${body}                Get Body                       timestamp=${timestamp}
    Fetch Data Product     ${body}

Fetch Data Product With Timestamp 200
    [Arguments]            ${increment}       ${time_zone}=UTC      ${result_format}=%Y-%m-%dT%H:%M:%S.%fZ
    Fetch Data Product With Timestamp         ${increment}    ${time_zone}    ${result_format}
    Integer                response status                200
    Array                  response body data items       minItems=2

Fetch Data Product With Timestamp 422
    [Arguments]            ${increment}
    Fetch Data Product With Timestamp         ${increment}
    Integer    response status                422
    Integer    response body error status     422
    String     response body error message    Request timestamp not within time frame.


*** Test Cases ***
fetch, 200
    [Tags]                bug-2259
    ${body}               Get Body
    Fetch Data Product    ${body}
    Integer     response status                                  200
    String      response body @context                           https://standards.lifeengine.io/v1/Context/Identity/Thing/HumanWorld/Product/DataProduct/
    String      response body data @context                      https://standards.lifeengine.io/v1/Context/Identity/Thing/HumanWorld/Product/DataProduct/
    String      response body data @type                         DataProduct
    Array       response body data items                         minItems=2
    String      response body data items 0 id site_name          lh_suokatu42_kuopio
    String      response body data items 0 id series_id          3C2FEE_hum
    String      response body data items 0 data 0 timestamp      2020-02-10 13:29:03
    Number      response body data items 0 data 0 value          26.0
    String      response body data items 0 data 1 timestamp      2020-02-10 13:59:38
    Number      response body data items 0 data 1 value          25.0
    String      response body data items 0 data 2 timestamp      2020-02-10 14:30:11
    Number      response body data items 0 data 2 value          26.0
    String      response body data items 1 id site_name          lh_suokatu42_kuopio
    String      response body data items 1 id series_id          3C2FEE_temp
    String      response body data items 1 data 0 timestamp      2020-02-10 13:29:03
    Number      response body data items 1 data 0 value          21.1
    String      response body data items 1 data 1 timestamp      2020-02-10 13:59:38
    Number      response body data items 1 data 1 value          21.1
    String      response body data items 1 data 2 timestamp      2020-02-10 14:30:11
    Number      response body data items 1 data 2 value          21.1
    String      response body signature type                     RsaSignature2018
    String      response body signature created
    String      response body signature creator                  https://api-external-${TESTENV}.oftrust.net/lh-translator/v1/public.key
    String      response body signature signatureValue
    String      response headers X-Product-Signature-Verified    True

fetch, 422, Missing data for parameters required field
    ${body}                Get Body
    Pop From Dictionary    ${body}                              parameters
    Fetch Data Product     ${body}
    Integer    response status                                  422
    Integer    response body error status                       422
    String     response body error message parameters dataTypes 0
    ...                                                         Missing data for required field.

fetch, 422, dataTypes as string => Not a valid list
    ${body}                Get Body
    Set To Dictionary      ${body["parameters"]}                dataTypes="Temperature"
    Fetch Data Product     ${body}
    Integer    response status                                  422
    Integer    response body error status                       422
    String     response body error message parameters dataTypes 0
    ...                                                         Not a valid list.

fetch, 422, dataTypes as empty list => Not a valid list
    ${body}                Get Body
    Set To Dictionary      ${body["parameters"]}                dataTypes=${EMPTY}
    Fetch Data Product     ${body}
    Integer    response status                                  422
    Integer    response body error status                       422
    String     response body error message parameters dataTypes 0
    ...                                                         Not a valid list.

fetch, 200, multiple dataTypes values
    [Tags]                 bug-2259
    ${body}                Get Body
    ${data_types}          Create List                          jimmy    johnny    jimbo
    Set To Dictionary      ${body["parameters"]}                dataTypes=${data_types}
    Remove From List       ${body["parameters"]["ids"]}         -1
    Set To Dictionary      ${body["parameters"]}                startTime=2020-02-10 13:59:38
    Set To Dictionary      ${body["parameters"]}                endTime=2020-02-10 14:30:12
    Fetch Data Product     ${body}
    Integer    response status                                  200
    Array      response body data items                         minItems=1    maxItems=1
    String     response body data items 0 id site_name          lh_suokatu42_kuopio
    String     response body data items 0 id series_id          3C2FEE_temp
    Array      response body data items 0 data                  minItems=2    maxItems=2
    String     response body data items 0 data 0 timestamp      2020-02-10 13:59:38
    Number     response body data items 0 data 0 value          21.1
    String     response body data items 0 data 0 type           jimmy
    String     response body data items 0 data 1 timestamp      2020-02-10 14:30:11
    Number     response body data items 0 data 1 value          21.1
    String     response body data items 0 data 1 type           jimmy

fetch, 422, missing ids
    [Tags]                 bug-2258
    ${body}                Get Body
    Pop From Dictionary    ${body["parameters"]}                ids
    Fetch Data Product     ${body}
    Integer    response status                                  422
    Integer    response body error status                       422
    String     response body error message                      Not known

fetch, 200, empty ids
    ${body}                Get Body
    Set To Dictionary      ${body["parameters"]}                ids=@{EMPTY}
    Fetch Data Product     ${body}
    Integer    response status                200
    String     response body @context         https://standards.lifeengine.io/v1/Context/Identity/Thing/HumanWorld/Product/DataProduct/
    String     response body data @context    https://standards.lifeengine.io/v1/Context/Identity/Thing/HumanWorld/Product/DataProduct/
    String     response body data @type       DataProduct
    Array      response body data items       maxItems=0

fetch, 422, missing startTime
    [Tags]                 bug-2256
    ${body}                Get Body
    Pop From Dictionary    ${body["parameters"]}                startTime
    Fetch Data Product     ${body}
    Integer    response status                                  422
    String     response body error message                      Not known

fetch, 422, invalid startTime
    [Tags]                 bug-2255
    ${body}                Get Body
    Set To Dictionary      ${body["parameters"]}                startTime=not a valid timestamp
    Fetch Data Product     ${body}
    Integer    response status                                  422
    String     response body error message                      Not known

fetch, 422, missing endTime
    [Tags]                 bug-2256
    ${body}                Get Body
    Pop From Dictionary    ${body["parameters"]}                endTime
    Fetch Data Product     ${body}
    Integer    response status                                  422
    String     response body error message                      Not known

fetch, 422, invalid endTime
    [Tags]                 bug-2254
    ${body}                Get Body
    Set To Dictionary      ${body["parameters"]}                endTime=not a valid timestamp
    Fetch Data Product     ${body}
    Integer    response status                                  422
    String     response body error message                      Not known

fetch, 422, no timezone
    [Tags]                 bug-2257
    ${timestamp}           Get Current Date   time_zone=UTC    result_format=%Y-%m-%dT%H:%M:%S.%f
    ${body}                Get Body       timestamp=${timestamp}
    Fetch Data Product     ${body}
    Integer    response status                                  422
    String     response body error message                      Not known

fetch, 200, with various valid timestamps
    [Template]      Fetch Data Product With Timestamp 200
    0            local    %Y-%m-%dT%H:%M:%S.%f${LOCAL_TZ}
    0            UTC      %Y-%m-%dT%H:%M:%S.%f+00:00
    1 hour       UTC      %Y-%m-%dT%H:%M:%S.%f+01:00
    12 hour      UTC      %Y-%m-%dT%H:%M:%S.%f+12:00
    -8 hour      UTC      %Y-%m-%dT%H:%M:%S.%f-08:00
    -4.2 sec
    -4 sec
    -3 sec
    -2 sec
    -1 sec
    0 sec
    1 sec
    2 sec
    3 sec
    4 sec
    4.2 sec

fetch, 200, with various invalid timestamps
    [Template]      Fetch Data Product With Timestamp 422
    -10 sec
    -9 sec
    -8 sec
    -7 sec
    -6 sec
    -5.8 sec
    5.5 sec
    6 sec
    7 sec
    8 sec
    9 sec
    10 sec
