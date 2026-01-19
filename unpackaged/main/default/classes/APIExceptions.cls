/**
 * @author Daniel Segal
 * @date 2020-07-29
 * @description Exceptions class for handling various REST API Errors
 */
global class APIExceptions {
    global class InvalidInputException extends Exception{
        global List<Error> errors;

        global InvalidInputException(Error err){
            errors=new List<Error>{err};
        }
    }


    global class Error{
        global String key;
        global String message;

        global Error(String key, String message){
            this.key=key;
            this.message=message;
        }
    }

}