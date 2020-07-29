using System.Threading.Tasks;
using Comments.Services;
using Microsoft.AspNetCore.Mvc;

namespace Comments.Controllers
{
    [Route("comments")]
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
