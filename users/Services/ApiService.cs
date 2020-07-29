using System;
using System.Net.Http;
using System.Threading.Tasks;
using Newtonsoft.Json;

namespace Users.Services
{
    public class ApiService
    {
        private readonly HttpClient _client;

        public ApiService(HttpClient client)
        {
            _client = client;
            _client.BaseAddress = new Uri("https://jsonplaceholder.typicode.com");
        }

        public async Task<dynamic> Delegate(string path)
        {
            using (var response = await _client.GetAsync(path))
            {
                response.EnsureSuccessStatusCode();

                return JsonConvert.DeserializeObject<dynamic>(await response.Content.ReadAsStringAsync());
            }
        }
    }
}
