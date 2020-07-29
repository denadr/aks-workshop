using Users.Services;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;

namespace Users.Controllers
{
    [Route("users")]
    [ApiController]
    public class DefaultController : ControllerBase
    {
        private readonly ApiService _service;

        public DefaultController(ApiService service)
        {
            _service = service;
        }

        [HttpGet]
        public async Task<ActionResult<dynamic>> Get()
        {
            return await _service.Delegate(Request.Path);
        }
    }
}
