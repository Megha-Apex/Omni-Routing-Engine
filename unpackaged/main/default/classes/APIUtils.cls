/**
 * @author Daniel Segal
 * @date 2020-07-29
 * @description Util class for handling various REST API functionality
 */
global with sharing class APIUtils {
    /**
     * @description Function gets url path and key to search
     * @param url path
     * @param key to search
     * @return Value of the key
     */
    global static String getUrlParamByKey(String url, String key) {
        String str = url.substringAfter('/' + key + '/').substringBefore('/');
        return(
                String.isNotBlank(str) && str.isNumeric()
                        ? dropZeros(str)
                        : str
        );
    }

    global static String dropZeros(String autoNum) {
        return String.valueOf(Integer.valueOf(autoNum));
    }

    /**
     * @description Responsible for generating the API response
     * @param msg response message
     * @param code response status
     * @return Value of the key
     */
    global static void responseMessage(String msg, Integer code) {
        if (RestContext.response == null) RestContext.response = new RestResponse();
        RestContext.response.statusCode = code;
        RestContext.response.addHeader('Content-Type', 'application/json');
        RestContext.response.responseBody = Blob.valueOf(msg);
    }

    /**
     * @description Used to generate an error with the relevant code
     * @param errors represents he list of errors
     * @param code of the error
     * @return Value of the key
     */
    global static void handleError(List<APIExceptions.Error> errors, Integer code) {
        Map<String, Object> out = new Map<String, Object> ();
        out.put('code', code);
        out.put('errors', errors);
        responseMessage(JSON.serialize(out), code);
    }

}