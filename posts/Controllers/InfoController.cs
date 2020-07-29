using System;
using System.Linq;
using System.Collections;
using System.Collections.Generic;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;

namespace Posts.Controllers
{
    [Route("")]
    [ApiController]
    public class InfoController : ControllerBase
    {
        [HttpGet]
        public ActionResult<dynamic> Get()
        {
            var variables = new List<(string name, string value)>();
            
            foreach (DictionaryEntry variable in Environment.GetEnvironmentVariables())
            {
                variables.Add((variable.Key.ToString(), variable.Value.ToString()));
            }

            return variables;
        }
    }
}
