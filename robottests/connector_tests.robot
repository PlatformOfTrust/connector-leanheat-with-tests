*** Settings ***
Library           Collections
Library           DateTime
Library           PoTLib
Library           REST         ${POT_API_URL}


*** Variables ***
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


*** Test Cases ***
fetch, 200
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

fetch, 500
    ${body}                Get Body
    Pop From Dictionary    ${body["parameters"]}                ids
    Fetch Data Product     ${body}
    Integer    response status                                  500
    Integer    response body error status                       500
