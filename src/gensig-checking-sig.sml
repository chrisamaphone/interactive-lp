signature GENSIG_CHECKING =
sig

  datatype response = Error of string | Yes | No

  val checkRule : (LinearLogicPrograms.context * LinearLogicPrograms.gensig) 
                -> (LinearLogicPrograms.context * LinearLogicPrograms.context)
                    -> response

end
