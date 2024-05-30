# Azure APIM GenAI policies

## Architecture Components

This repository contains the Bicep templates for deploying the following components:

- Azure APIM Developer Sku
- Azure Application Insights
- Azure OpenAI Cognitive Services (3)

APIM GenAI capabilities demonstrated in this repository include:

- Load balancing and Circuit breaker policies
- Token Rate limiting policies
- Emit Token metrics to Application Insights
- User Managed Identity Authentication for Cognitive Services

## Deployment

Deploy the template to the Azure subscription using the following command:

```bash
    az deployment sub create --name apim-genai --template-file main.bicep --parameters parameters.json --location francecentral
```

## Testing

1. Open the *AzureOpenAI* API in the Azure APIM instance and navigate to the test tab.
1. Select the POST method for *Creates a completion for the chat message*
1. Fill the template parameters as follows
    - deployment-id: chat
    - api-version: 2024-02-01
1. Overwrite the *Request body* with the below
    ```json
    {"temperature":1,"top_p":1,"stream":false,"stop":null,"max_tokens":2000,"presence_penalty":0,"frequency_penalty":0,"logit_bias":{},"user":"user-1234","messages": [{"role":"system","content":"You are an AI assistant that helps people find information"},{"role":"user","content":"Negate the following sentence.The price for bubblegum increased on thursday."}],"n":1}
    ```
1. Click send and observe the response
    - x-ms-region changing to the region of AOAI service that served the request
1. Metrics can be observed in the Application Insights instance created in the same resource group as the APIM instance.
    - Metric blade -> select *genaitest* in the *Metric Namespace* dropdown
    - Logs blade -> Tables -> customMetrics has the custom metrics emitted by the APIM policies. customDimensions field contains the dimension which can be used to aggregate the metrics.
1. Update the azure-openai-token-limit policy for the API to use 100 as the tokens-per-minute and the second request should return a 429 response which is issued by APIM,

## Streaming

For metric collection with streaming, follow the below instructions:

1. Change the buffering property on the forward-request policy as mentioned below
   
   ```yaml
   <forward-request buffer-response="false" />
   ```
2. Use the curl command below to test streaming

   ```bash
   curl -N https://{yourapimname}.azure-api.net/openai/deployments/chat/chat/completions?api-version=2024-02-01 -H "Content-Type: application/json" -H "ocp-apim-subscription-key: {yoursubscriptionkey}" -d "{\"temperature\":1,\"top_p\":1,\"stream\":true,\"stop\":null,\"max_tokens\":2000,\"presence_penalty\":0,\"frequency_penalty\":0,\"logit_bias\":{},\"user\":\"user-1234\",\"messages\": [{\"role\":\"system\",\"content\":\"You are an AI assistant that helps people find information\"},{\"role\":\"user\",\"content\":\"Write a 10 page story on greek mythology.\"}],\"n\":1}"
   ```
