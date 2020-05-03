
#' Car Delete Module
#'
#' This module is for deleting a row's information from the mtcars database file
#'
#' @importFrom shiny observeEvent req showModal h3 modalDialog removeModal actionButton modalButton
#' @importFrom DBI dbExecute
#' @importFrom shinyFeedback showToast
#'
#' @param modal_title string - the title for the modal
#' @param car_to_delete string - the model of the car to be deleted
#' @param modal_trigger reactive trigger to open the modal (Delete button)
#'
#' @return None

car_delete_module <- function(input, output, session, modal_title, car_to_delete, modal_trigger) {
  ns <- session$ns
  # Observes trigger for this module (here, the Delete Button)
  observeEvent(modal_trigger(), {
    # Authorize who is able to access particular buttons (here, modules)
    req(session$userData$email == 'tycho.brahe@tychobra.com')

    showModal(
      modalDialog(
        h3(
          paste("Are you sure you want to delete the information for the", car_to_delete()$model, "car?")
        ),
        title = modal_title,
        size = "m",
        footer = list(
          actionButton(
            ns("delete_button"),
            "Delete Car",
            style="color: #fff; background-color: #dd4b39; border-color: #d73925"),
          modalButton("Cancel")
        )
      )
    )
  })



  observeEvent(input$delete_button, {
    req(modal_trigger())

    removeModal()

    car_out <- car_to_delete()

    car_out$is_deleted <- TRUE
    car_out$modified_at <- as.character(lubridate::with_tz(Sys.time(), tzone = "UTC"))
    car_out$modified_by <- session$userData$email
    car_out$created_at <- as.character(car_out$created_at)

    tryCatch({

      uid <- uuid::UUIDgenerate()

      dbExecute(
        session$userData$conn,
        "INSERT INTO mtcars (uid, id_, model, mpg, cyl, disp, hp, drat, wt, qsec, vs, am,
        gear, carb, created_at, created_by, modified_at, modified_by, is_deleted) VALUES
        ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19)",
        params = c(
          list(uid),
          unname(car_out)
        )
      )

      session$userData$db_trigger(session$userData$db_trigger() + 1)
      showToast("success", "Car Successfully Deleted")
    }, error = function(error) {

      showToast("error", "Error Deleting Car")

      print(error)
    })
  })
}