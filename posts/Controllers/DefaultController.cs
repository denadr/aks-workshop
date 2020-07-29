using System.Threading.Tasks;
using Posts.Services;
using Microsoft.AspNetCore.Mvc;

namespace Posts.Controllers
{
    [Route("posts")]
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
